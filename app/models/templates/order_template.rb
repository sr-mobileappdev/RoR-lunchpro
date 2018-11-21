class Templates::OrderTemplate < Templates::BaseTemplate
  attr_reader :order

  def initialize(obj = nil)
    @object_type = obj.class
    @order = obj
  end

  def tags
    return [] if !@order
    {
      order_number: 'order_number',
      restaurant_name: 'restaurant_name',
      subtotal: 'subtotal',
      price_per_person: 'price_per_person',
      item_count: 'item_count',
      rating: 'rating',
      view_office_order_url: 'view_office_order_url',
      view_rep_order_url: 'view_rep_order_url',
      view_restaurant_order_url: 'view_restaurant_order_url',
      view_restaurant_order_url_edit: 'view_restaurant_order_url_edit',
      comment: 'comment',
      original_tip_amount: 'original_tip_amount',
      new_tip_amount: 'new_tip_amount',
      review_presentation: 'review_presentation',
      review_food_quality: 'review_food_quality',
      review_completeness: 'review_completeness',
      review_on_time: 'review_on_time',
      review_comments: 'review_comments',
      orderer: 'orderer',
      orderer_email: 'orderer_email',
      orderer_phone: 'orderer_phone',
      leave_review_url: "leave_review_url",
      office_review_comments: "office_review_comments",
      updated_at: "updated_at",
      recommended_by_full_name: "recommended_by_full_name",
      recommended_by_email: "recommended_by_email",
      recommended_by_phone: "recommended_by_phone",
      transaction_error: "transaction_error",
      transaction_time: "transaction_time",
      order_details_table: 'order_details_table',
      rest_mgr_order_sums: 'rest_mgr_order_sums',
      confirm_order_url: 'confirm_order_url'
    }
  end

  def __confirm_order_url
    crypt = ActiveSupport::MessageEncryptor.new(ENV['PASSCODE_KEY'])
    encrypted_data = crypt.encrypt_and_sign(@order.id)
    UrlHelpers.confirm_api_email_orders_url(uid: encrypted_data)
  end

  def __transaction_time
    if @@options && @@options['order_tranx_time']
      ApplicationController.helpers.long_date(@@options['order_tranx_time'].to_datetime)
    end
  end

  def __transaction_error
    if @@options && @@options['order_tranx_error']
      @@options['order_tranx_error']
    end
  end

  def __poc_name_or_nil
    if @@options && @@options['poc'].present?
      @@options['poc']['full_name']
    else
      @office.manager_name
    end
  end

  def __recommended_by_full_name
    user = User.find(@order.recommended_by_id) if @order.recommended_by_id
    if user
      user.display_name
    end
  end

  def __recommended_by_email
    user = User.find(@order.recommended_by_id) if @order.recommended_by_id
    if user
      user.email
    end
  end

  def __recommended_by_phone
    user = User.find(@order.recommended_by_id) if @order.recommended_by_id
    if user
      ApplicationController.helpers.format_phone_number_string(user.primary_phone || user.entity.phone)
    end
  end

  def __updated_at
    ApplicationController.helpers.long_date(@order.updated_at.in_time_zone("Central Time (US & Canada)"))    
  end

  def __leave_review_url
    if @order.appointment && @order.appointment.sales_rep
      UrlHelpers.rep_order_url(@order)
    elsif @order.appointment && !@order.appointment.sales_rep
      UrlHelpers.office_order_url(@order)
    end
  end

  def __orderer
    @order.customer_name
  end

  def __orderer_phone
    @order.customer_phone
  end

  def __orderer_email
    @order.customer_email
  end

  def __item_count
    @order.total_items
  end

  def __subtotal
    ApplicationController.helpers.precise_currency_value(@order.subtotal_cents)
  end

  def __review_presentation
    review = @order.active_review('SalesRep')
    if review
      review.presentation
    else
      'n/a'
    end
  end

  def __review_food_quality
    review = @order.active_review('SalesRep')
    if review
      review.food_quality
    else
      'n/a'
    end
  end

  def __review_completeness
    review = @order.active_review('SalesRep')
    if review
      review.completion
    else
      'n/a'
    end
  end

  def __review_on_time
    review = @order.active_review('SalesRep')
    if review
      review.on_time ? "Yes" : "No"
    else
      'n/a'
    end
  end

  def __review_comments
    review = @order.active_review('SalesRep') || @order.active_review('Office')
    if review
      review.comment
    else
      'n/a'
    end
  end

  def __office_review_comments
    review = @order.active_review('Office')
    if review
      review.comment
    else
      'n/a'
    end
  end

  def __rating
    @order.active_review('Office').overall
  end

  def __comment
    @order.active_review('Office').comment || "The office didn't leave any feedback"
  end

  def __price_per_person
    ApplicationController.helpers.precise_currency_value(@order.per_person_cost_cents)
  end

  def __new_tip_amount
    ApplicationController.helpers.precise_currency_value(@order.tip_cents)
  end

  def __original_tip_amount
    if @@options && @@options['previous_tip_amount']
      ApplicationController.helpers.precise_currency_value(@@options['previous_tip_amount'])
    end
  end

  def __restaurant_name
    @order.restaurant.name if @order.restaurant
  end

    def __view_rep_order_url
    UrlHelpers.rep_order_url(@order)
  end
  def __view_office_order_url
    UrlHelpers.office_order_url(@order)
  end

  def __view_restaurant_order_url
    UrlHelpers.detail_restaurant_order_url(@order)
  end

  def __view_restaurant_order_url_edit
    UrlHelpers.detail_restaurant_order_url(@order, edit: true)
  end

  def __order_details_table
    ac = ActionController::Base.new()
    ah = ApplicationController.helpers
    ##should style table in email content and render <trs> in partial
    table = ac.render_to_string(partial: 'shared/notification_partials/order_details_table', :layout => false, locals:{order: @order, ah: ah}, :formats => [:html])
    table.html_safe
  end
  
  def __rest_mgr_order_sums
	ac = ActionController::Base.new()  
  	ah = ApplicationController.helpers
    sums = ac.render_to_string(partial: 'shared/notification_partials/rest_mgr_order_sums', :layout => false, locals:{order: @order, ah: ah}, :formats => [:html])
    sums.html_safe
  end
end