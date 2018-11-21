class User < ApplicationRecord
  include LunchproRecord
  attr_reader :raw_invitation_token

	belongs_to :validated_by, class_name: 'User'

	has_many :payment_methods, dependent: :destroy
	has_many :order_transactions, through: :payment_methods

	has_many :orders, foreign_key: 'created_by_user_id'

  has_many :notifications, dependent: :destroy
  has_many :user_devices, -> { where.not(status: ["deleted"]) }
  has_many :user_notification_prefs, -> { where.not(status: ["deleted"]) }
  has_one :user_office, dependent: :destroy
  has_one :sales_rep, dependent: :destroy
  has_many :user_restaurants, dependent: :destroy # might have more than one
  has_one :user_restaurant
  
  accepts_nested_attributes_for :sales_rep, allow_destroy: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  validates_confirmation_of :password
  validates_format_of :email, 
  :with =>/.+@.+\..+/i

  enum space: { space_admin: 1, space_sales_rep: 2, space_office: 3, space_restaurant: 4, space_onboarding: 5 }

  before_create :set_default_space
    
  def sales_rep
    sales_rep.where(:status => 'active').first
  end

  def authenticate(password_to_test)
  	if !valid_password?(password_to_test)
  		return false
  	end
  	if !confirmed_at.present? && !invitation_accepted_at.present?
  		return false
  	end
  	
  	return self.active?
  end

  before_save :flag_for_notifications
  after_save :trigger_notifications
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update
  
  def create_validations
  	if space == 'space_sales_rep' && primary_phone.present? && User.select{ |user| user.space == "space_sales_rep" && user.primary_phone && user.primary_phone.gsub(/\D/, '') == primary_phone.gsub(/\D/, '') && user.active? && user.id != id }.any?
  		self.errors.add(:base, "Primary phone number is not unique")
  	end
  	if space == 'space_sales_rep' && !primary_phone.present?
  		self.errors.add(:base, "Primary phone number is missing")
  	end
  	return self.errors.count == 0
  end
  
  def update_validations
  	if space == 'space_sales_rep' && primary_phone.present? && User.select{ |user| user.space == "space_sales_rep" && user.primary_phone && user.primary_phone.gsub(/\D/, '') == primary_phone.gsub(/\D/, '') && user.active? && user.id != id }.any?
  		self.errors.add(:base, "Primary phone number is not unique")
  	end
  	if space == 'space_sales_rep' && !primary_phone.present?  	
  		self.errors.add(:base, "Primary phone number is missing")
  	end
  	return self.errors.count == 0
  end

  def flag_for_notifications
    @notify_password_changed = false
    @notify_account_deleted = false
    @notify_password_reset = false
    if !self.new_record? && self.encrypted_password_changed? && self.status == 'active' && !self.invitation_accepted_at_changed? && (invitation_accepted? || confirmation_accepted?)
      @notify_password_changed = true
    elsif !self.new_record? && self.reset_password_token_changed? && self.status == 'active'
      @notify_password_reset = true
    elsif self.new_record? && self.space == "space_admin"
      
    elsif self.status_changed? && self.status_was == "active" && self.status == 'inactive' && self.deactivated_at_changed? && self.deactivated_at.present? && self.entity
      @notify_account_deleted = true
    end
      
  end

  def trigger_notifications
    begin
      if @notify_password_changed
        if self.space == "space_office"
          Managers::NotificationManager.trigger_notifications([108], [self, entity])
        else
          Managers::NotificationManager.trigger_notifications([212], [self, entity])
        end
      elsif @notify_password_reset
        #Managers::NotificationManager.trigger_notifications([418], [self, entity])
      elsif @notify_account_deleted
        if self.space == "space_sales_rep"
          Managers::NotificationManager.trigger_notifications([419], [entity], {entity: {type: "Sales Rep", name: entity.full_name, 
            phone_number: entity.phone_record("business"), email_address: entity.email("business") }})
        else
          Managers::NotificationManager.trigger_notifications([419], [self, entity], {entity: {type: entity.class.name, name: self.display_name, 
            phone_number: self.primary_phone, email_address: self.email}})
        end
      end
        
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end

  def set_default_space
    if self.space.nil?
      self.space = "space_sales_rep"
    end
  end

  def validate!(admin_user)
    self.validated_at = Time.zone.now
    self.validated_by = admin_user
    self.save
  end

  def notification_preferences
    @preferences = []
    if space_admin? 
      NotificationEvent.active.each do |ne|
        if ne.notification_event_recipients.where(recipient_type: "admin").count > 0
          @preferences << Views::NotificationPreference.new(ne, self)
        end
      end
    else
      NotificationEvent.active.each do |ne|
        if ne.notification_event_recipients.where(recipient_type: space.split("_", 2).last).count > 0
          @preferences << Views::NotificationPreference.new(ne, self)
        end
      end
    end

    @preferences
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
        when 'space_office'
          params["space"] = "space_office"
        when 'space_restaurant'
          params["space"] = "space_restaurant"
        # when "recent"
        #   params["status"] = "inactive"
        #   params["created_at"] = {"operator" => "gt", "condition" => Time.now - 30.days }
      end
    end

    params
  end

  #these are the prefs that will be set on account creation
  def self.default_admin_notifications(email = true)
    if email
      {"101":"1","103":"1","104":"1","105":"1","106":"1","107":"1", "118":"1", "120":"1", "121":"1", "204":"1", "205":"1", "206":"1", "207":"1", "209":"1", "211":"1", 
        "301":"1", "302":"1", "303":"1", "401":"1","405":"1", "407":"1", "408":"1", "418":"1"}
    else

    end

  end

  #these are the prefs that will be set on account creation
  def self.default_rep_notifications(email = true)
    if email
      {"102":"1", "103":"1","104":"1","105":"1","106":"1","107":"1","109":"1","110":"1","111":"1",
        "112":"1","113":"1","114":"1","115":"1","116":"1","118":"1","201":"1","202":"1","203":"1","204":"1","205":"1","206":"1","207":"1",
        "213":"1","214":"1","402":"1","403":"1",
        "404":"1","411":"1","415":"1","416":"1"}.merge(self.standard_rep_notifications(true))
    else
      {"102":"1", "103":"1","104":"1","105":"1","106":"1","107":"1","109":"1","110":"1","111":"1",
        "112":"1","113":"1","114":"1","115":"1","116":"1","118":"1","201":"1","202":"1","203":"1","204":"1","205":"1","206":"1","207":"1",
        "213":"1","214":"1","402":"1","403":"1",
        "404":"1","411":"1","415":"1","416":"1"}.merge(self.standard_rep_notifications(false))
    end
  end


  #these will ALWAYS be set for sms/email
  def self.standard_rep_notifications(email = true)
    if email
      {'209':'1', '100':'1', '212': '1', '215': '1', '216': '1', '217': '1', '401': '1', '417': '1', '418': '1', '419': '1'}
    else
      {'209': '1', '212': '1', '215': '1', '216': '1', '217': '1', '401': '1', '417': '1', '418': '1', '419': '1'}
    end
  end

  #these are the prefs that will be set on account creation
  def self.default_office_notifications(email = true)
    if email
      {'212': '1', "112":"1", "117":"1", "201":"1", "202":"1", "103":"1", "104":"1", "204":"1", "205":"1", "203":"1", "206":"1", "208":"1", "409":"1", "119":"1", "120":"1", "121":"1",
        "410":"1"}.merge(self.standard_office_notifications(true))
    end
  end

  #these will ALWAYS be set for sms/email
  def self.standard_office_notifications(email = true)
    if email
      {"100":"1","101":"1","108":"1","401":"1","412":"1","418":"1","419":"1"}
    end
  end

  #these will ALWAYS be set for sms/email
  def self.standard_restaurant_notifications(email = true)
    if email
      {"303":"1","405":"1","413":"1","418":"1","419":"1"}
    else
      {"303":"1","405":"1"}
    end
  end

  #these will be set on account creation
  def self.default_restaurant_notifications(email=true)
    if email
      {"116":"1","119":"1","120":"1","121":"1","203":"1","204":"1","206":"1","207":"1","208":"1","210":"1","212":"1","301":"1","302":"1",
        "303":"1","405":"1","406":"1","408":"1","413":"1","418":"1","419":"1"}
    else
      {"116":"1","119":"1","120":"1","121":"1","203":"1","204":"1","206":"1","207":"1","208":"1","210":"1","301":"1","302":"1","303":"1","405":"1","406":"1","408":"1"}
    end
  end

  # --
  def generate_access_token
    token = UserAccessToken.generate!(self)
    (token) ? token.access_token : nil
  end

  def sales_rep
    rep = SalesRep.where(user_id: self.id, :status => 'active').first
  end

  #used to determine what entity a user has, and returns that entity
  def entity
    case space 
    when "space_office"
      user_office.office
    when "space_restaurant"
      user_restaurant.restaurant
    when "space_sales_rep"
      sales_rep
    when 'space_admin'
      nil
    end
  end

  def self.end_impersonation_path(user)
    return nil if !user

    case user.entity.class.name

    when "SalesRep"
      UrlHelpers.end_impersonation_rep_profile_index_path
    when "Office"
      UrlHelpers.end_impersonation_office_account_path
    when 'Restaurant'
      UrlHelpers.end_impersonation_restaurant_account_index_path
    end
  end

  def admin_view
    @admin_view ||= Views::Admin.for_user(self)
  end

  def display_name
    (first_name && last_name) ? "#{first_name} #{last_name}" : email
  end

  def poc_info
    {
      full_name: self.display_name, 
      email_address: self.email, 
      phone_number: self.primary_phone
    }
  end

  def display_space
    if space
      space.gsub("space_", "").humanize
    else
      ""
    end
  end

  def restaurant_manager?
    self.user_restaurant.present? && self.user_restaurant.restaurant.is_headquarters?
  end

  def is_admin?
    self.space == 'space_admin'
  end

  def default_payment_method
    payment_methods.active.order(:sort_order).first
  end

  def non_default_payment_methods
    payment_methods.active.where.not(:id => default_payment_method.id).order(:sort_order) if default_payment_method
  end

  def visible_notifications
    notifications.visible
  end

  def notification_recipient_type
    if space
      val = space.gsub("space_", "")
      val
    else
      ""
    end
  end

  def invitation_accepted?
    invitation_accepted_at != nil
  end

  def confirmation_accepted?
    confirmed_at != nil
  end

  def invite_status
    if invitation_accepted?
      "Accepted"
    elsif invitation_sent_at
      "Invite Pending"
    else
      "No Invite Sent"
    end
  end

  def confirmation_status
    if confirmation_accepted?
      "Confirmed"
    elsif confirmation_sent_at
      "Confirmation Pending"
    else
      "No Confirmation Sent"
    end
  end

  # to utilize send_later to send emails through queue
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def self.__columns
    cols = {display_name: 'Name', display_space: 'Space'}
    hidden_cols = [:encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :last_sign_in_at, :last_sign_in_ip]
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
