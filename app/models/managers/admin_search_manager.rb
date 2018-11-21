class Managers::AdminSearchManager
  attr_reader :search
  attr_writer :relation
  attr_writer :column_keys
  DEFAULT_PER_PAGE = 50

  def initialize(search, cols, scope_params = nil)
    @search = search
    @model = search.search_model
    @column_keys = cols
    @scope_params = scope_params
    @relation = nil
  end

  def scoped
    return @relation unless @scope_params
    relation = @model.classify.constantize

    ar_model = relation.arel_table

    @scope_params.each do |sp_key, sp_val|
      next unless sp_key && sp_val
      if sp_val.kind_of?(Hash)
        # special conditional
      elsif sp_val.kind_of?(Array)
        # in conditional
        relation = relation.where(ar_model[sp_key].in(sp_val))
      else
        # straight equals conditional
        relation = relation.where(ar_model[sp_key].eq(sp_val))
      end
    end
    @relation = relation
    self
  end

  def paged_results(page = 1, per_page = DEFAULT_PER_PAGE, order_by = nil)
    if order_by
      results.order(order_by).page(page).per(per_page)
    else
      results.page(page).per(per_page)
    end
  end

  def results
    begin
      relation = @relation
      klass = @model.classify.constantize
      return relation.all unless @search.conditions && @search.conditions["wheres"]    
      relation_added = false
      virtual_attrs = []
      @search.conditions["wheres"].each do |k,v|
        next if !v.present?
        #if search conditon is a column attr
        if @relation.column_names.include? k
          relation = add_condition(klass, relation, k, v)
          relation_added = true
        #els if search condition is not a column attr, but is a virtual attr
        elsif !@relation.column_names.include? k
          virtual_attrs << {name: k, val: v} if @relation.method_defined? k
        end
      end

      #if any virtual attr conditions, create chained condition
      if virtual_attrs.any?
        if virtual_attrs.first[:name] == "sales_rep_phone"
          if virtual_attrs.first[:val].length == 14
            conditions = virtual_attrs.collect{|v| "rel.#{v[:name]}.to_s.downcase == '#{v[:val].downcase}' || "}.join << "#{relation_added}"
          elsif virtual_attrs.first[:val].length == 10
            conditions = virtual_attrs.collect{|v| "rel.#{v[:name]}.to_s.downcase == '#{v[:val].downcase}' || "}.join << "#{relation_added}"
          else
            conditions = virtual_attrs.collect{|v| "rel.#{v[:name]}.to_s.downcase.include?('#{v[:val].downcase.gsub(/[() -]/,'')}') || "}.join << "#{relation_added}"
          end
        else
          conditions = virtual_attrs.collect{|v| "rel.#{v[:name]}.to_s.downcase == '#{v[:val].downcase}' || "}.join << "#{relation_added}"
        end

        relation = relation.where(:id => relation.select{|rel| eval(conditions)}.pluck(:id))
      end
      return relation
    rescue Exception => ex
      Rollbar.error(ex)
      raise ex if Rails.env.development?
    end


  end

  def add_condition(klass, relation, key, value)
    return relation unless value.present?
    ar = klass.arel_table
    relation = relation.where(ar[key.to_sym].matches("%#{value}%"))

    relation
  end



  def column_names
    model = @model.classify.constantize
    return @column_keys unless model && model.respond_to?("__columns")
    columns = model.send("__columns")

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
