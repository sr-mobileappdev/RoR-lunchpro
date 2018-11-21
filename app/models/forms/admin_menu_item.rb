class Forms::AdminMenuItem < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :menu_item
  attr_reader :menu_sub_items
  attr_reader :menu

  def initialize(user, menu = nil, params = {}, existing_menu_item = nil)
    @current_user = user
    @params = params
    @menu = menu
    @errors = []

    @assign_to_menus = []

    @menu_item = existing_menu_item
    @menu_sub_items = (existing_menu_item) ? existing_menu_item.menu_sub_items : nil
  end

  def valid?
    raise "Missing required parameters (:menu_item)" unless @params[:menu_item]
    # Validate office
    @menu_item ||= MenuItem.new(status: 'inactive')
    
    @menu_item.assign_attributes(@params[:menu_item])

    if @params[:diet_restrictions].present?
      new_restrictions = DietRestriction.where(id: (@params[:diet_restrictions].to_h.map { |k,v| (v == "1") ? k : nil }.compact))
      @menu_item.assign_attributes(diet_restrictions: new_restrictions)
    end

    if @params[:diet_restriction]
      if @params[:diet_restriction][:name].present?
        @menu_item.diet_restrictions.new(name: @params[:diet_restriction][:name], description: @params[:diet_restriction][:description])
      end
    end


    unless @menu_item.valid?
      @errors += @menu_item.errors.full_messages
    end



    return (@errors.count == 0)
  end

  def save
    if valid? && persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      @menu_item.menus << @menu if @menu && @menu_item.new_record?
      if @menu_item.save


        # Assign to appropriate menus if needed
        if @params && @params[:menus].present?
          @assign_to_menus = Menu.where(id: @params[:menus].to_h.map { |m,v| m if v.to_i == 1 })
          @menu_item.menus = @assign_to_menus
          @menu_item.save
        end

        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
