class UserRestaurant < ApplicationRecord
  include LunchproRecord

  belongs_to :user
  belongs_to :restaurant

  #used for Restaurant Managers when setting current restaurant
  attr_accessor :current_restaurant_id


  def determine_notification_trigger_url(event, related_objects)
    return '#' if !related_objects
    trigger_obj = {trigger_url: '#', modal: false, modal_size: nil}
    case event.category_cid.to_i
      when 119
        trigger_obj[:trigger_url] = UrlHelpers.detail_restaurant_order_path(related_objects[:order_id])
      when 120
        trigger_obj[:trigger_url] = UrlHelpers.detail_restaurant_order_path(related_objects[:order_id])
      when 121
        trigger_obj[:trigger_url] = UrlHelpers.detail_restaurant_order_path(related_objects[:order_id])
      when 203
        trigger_obj[:trigger_url] = UrlHelpers.detail_restaurant_order_path(related_objects[:order_id])
      when 206
        trigger_obj[:trigger_url] = UrlHelpers.detail_restaurant_order_path(related_objects[:order_id])
      when 207
      #  trigger_obj[:trigger_url] = order_detail_restaurant_orders_path(related_objects[:order_id])
      when 408
        trigger_obj[:trigger_url] = UrlHelpers.restaurant_orders_path
    end
    trigger_obj
  end
end
