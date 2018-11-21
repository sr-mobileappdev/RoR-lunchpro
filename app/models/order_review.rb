class OrderReview < ApplicationRecord
  include LunchproRecord
	# Schema Notes:
		# Hide completion and on_time from the office when they review an order

	belongs_to :order
  belongs_to :reviewer, polymorphic: true
  belongs_to :created_by, class_name: 'User'

  validates_presence_of :order 
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  before_save :set_overall

  enum reviewer_type: {SalesRep: '1', Office: '2'} 

  before_save :flag_for_notifications
  after_save :trigger_notifications

  def flag_for_notifications
    @notify_order_review_created = false
    if self.new_record? && self.status == 'active' && self.reviewer_type == 'SalesRep'
      @notify_order_review_created = true
    end
  end

  def trigger_notifications
    begin
      if @notify_order_review_created
        Managers::NotificationManager.trigger_notifications([210], [self, self.order, self.order.restaurant])
      end
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end

  def create_validations
    if reviewer_type == "SalesRep" && (!reviewer_id.present? || !food_quality.present? || !presentation.present? || !completion.present? || 
      !defined?(on_time) || !order_id.present?)
      self.errors.add(:base, "You must completely fill out the form before submitting a review.")
    elsif reviewer_type == 'Office' && ((!reviewer_id.present? || !overall.present? || !order_id.present?) && !(food_quality.present? && presentation.present? && completion.present?))
      self.errors.add(:base, "You must completely fill out the form before submitting a review.")
    end
  end

  def set_overall
    if food_quality.present? && presentation.present? && completion.present?
      self.overall = (food_quality + presentation + completion) / 3
    end
  end

  def update_validations
    create_validations
  end

  def on_time_display
    if reviewer_type == "SalesRep"
      on_time ? "Yes" : "No"
    else
      "--"
    end
  end
  
  def reviewer_name
  	if !self.reviewer.present?
  		return ""
  	end
  	if self.reviewer_type == 'SalesRep'
  		return self.reviewer.full_name
  	end
  	if self.reviewer_type == 'Office'
  		return self.reviewer.name
  	end
  	return ""
  end

   # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [])
    params = {}

    scope_strings.each do |scope|
      case scope
        when "active"
          params["status"] = "active"
        when "inactive"
          params["status"] = "inactive"
        when "past"
          params["status"] = "completed"
        when "draft"
          params["status"] = "draft"
        # when "recent"
        #   params["status"] = "inactive"
        #   params["created_at"] = {"operator" => "gt", "condition" => Time.now - 30.days }
      end
    end

    params
  end

end
