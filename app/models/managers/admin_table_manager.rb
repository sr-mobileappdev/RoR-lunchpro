class Managers::AdminTableManager
  attr_writer :relation
  attr_writer :model
  attr_writer :column_keys
  attr_writer :scope_params
  DEFAULT_PER_PAGE = 50

  def initialize(relation, cols, scope_params = nil, extra_params = nil, includes = nil)
    if relation.kind_of?(ActiveRecord::Relation)
      @relation = relation
      @model = @relation.class
    else
      @relation = relation.all
      @model = relation
    end
    @column_keys = cols
    @scope_params = scope_params
    @extra_params = extra_params
    if includes
      @relation = @relation.includes(includes)
    end
  end

  def scoped

    return @relation unless @scope_params
    relation = @relation

    ar_model = @model.arel_table
    
    @scope_params.each do |sp_key, sp_val|
      next unless sp_key
      if sp_val.kind_of?(Hash)
        if sp_val[:operator] && sp_val[:condition]
          # special conditional
          arel_method = sp_val[:operator]
          arel_value = sp_val[:condition]
          next unless arel_method.present?
          next unless ar_model[sp_key].respond_to?(arel_method)

          relation = relation.where(ar_model[sp_key].send(arel_method, arel_value))
        end

      elsif sp_val.kind_of?(Array)
        # in conditional
        relation = relation.where(ar_model[sp_key].in(sp_val))
      else
        # straight equals conditional
        relation = relation.where(ar_model[sp_key].eq(sp_val))
        if @extra_params.present?
          relation = relation.where(@extra_params.downcase == 'true')
        end
      end
    end
    @relation = relation

    #byebug
    self
  end

  def paged_results(page = 1, per_page = DEFAULT_PER_PAGE, order_by = nil)
    if order_by
      results.order(order_by).page(page).per(per_page)
    else
      results.page(page).per(per_page)
    end
  end

  def paged(page = 1, per_page = DEFAULT_PER_PAGE, order_by = "id", multiple_order = false)
    if multiple_order
      @relation.order(multiple_order).page(page).per(per_page)
    else
      @relation.order("#{order_by} desc").page(page).per(per_page)
    end
  end

  def paged2(page = 1, per_page = DEFAULT_PER_PAGE, order_by = "id", multiple_order = false) # ORDERED NON DESCENDING
    if multiple_order
      @relation.order(multiple_order).page(page).per(per_page)
    else
      @relation.page(page).per(per_page).order(order_by)
    end
  end

  def pagedOrdered(page = 1, per_page = DEFAULT_PER_PAGE, order_by = "id", multiple_order = false) # ORDERED NON DESCENDING
    if multiple_order
      @relation.order(multiple_order).page(page).per(per_page)
    else
      @relation.order("#{order_by}").page(page).per(per_page)
    end
  end


  # -- Custom methods for various needs

  def for_office(office)
    @relation.find_in_range_to_office(office)
  end

  # --



  def column_names
    return @column_keys unless @model && @model.respond_to?("__columns")
    columns = @model.send("__columns")

    cols = []
    @column_keys.each do |c|
      cols << columns[c.to_sym] if columns[c.to_sym]
    end

    cols
  end

  def columns
    @column_keys
  end
end
