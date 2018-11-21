class Admin::NotificationEvents::NotificationEventRecipientsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :test, :send_test, :reset_defaults]
  before_action :set_ace_editor, only: [:edit, :new, :show]

  def set_ace_editor
    @ace_editor = true
  end

  def set_parent_record
    @event = NotificationEvent.find(params[:notification_event_id])
  end

  def set_record
    @record = NotificationEventRecipient.find(params[:id])
  end

  def show

  end

  def new
    @record = NotificationEventRecipient.new(notification_event_id: @event.id)

  end

  def edit

  end

  def create

    form = Forms::AdminNotificationEventRecipient.new(@event, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create notification due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create notification at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New notification recipient has been created."
    render :json => {success: true, redirect: admin_notification_event_notification_event_recipient_path(@event, form.notification_event_recipient) }
    return

  end

  def update

    form = Forms::AdminNotificationEventRecipient.new(@event, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update notification due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update notification at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Notification details have been updated."
    render :json => {success: true, redirect: admin_notification_event_notification_event_recipient_path(@event, form.notification_event_recipient) }
    return

  end

  def test
    if @xhr
      render json: { html: (render_to_string :partial => 'test', :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  def send_test

    if params[:sms_phone].present?

    end

    if params[:email_address].present?
      begin
        NotificationMailer.simulate_notification(@record, current_user, params[:email_address]).deliver!
        flash[:notice] = "Test notification(s) will be sent momentarily to the email and/or phone numbers you requested."
      rescue Exception, SparkPostRails::DeliveryException => ex
        error_message = "Unable to send test to #{params[:email_address]}."
        if ex.kind_of?(SparkPostRails::DeliveryException)
          if ex.service_code == "1902"
            error_message += " You have entered an invalid or non-existant email address."
          else
            error_message += " Mail delivery error through Sparkpost #{ex.message}"
          end
        end
        flash[:alert] = error_message
      end
    end

    redirect_to admin_notification_event_path(@event)

  end

  def activate
    @record.active!

    flash[:notice] = "Notification recipient has been activated."
    render :json => {success: true, redirect: admin_notification_event_notification_event_recipient_path(@event, @record) }
  end

  def deactivate
    @record.inactive!

    flash[:alert] = "Notification recipient has been deactivated."
    render :json => {success: true, redirect: admin_notification_event_notification_event_recipient_path(@event, @record) }
  end

  def reset_defaults
    changed_prefs = []
    changed_prefs << "email" if @record.is_email_default
    changed_prefs << "sms" if @record.is_sms_default
    @record.reset_defaults!(changed_prefs, current_user)

    flash[:notice] = "Notification default preferences have been updated across all users for this notification type."
    render :json => {success: true, redirect: admin_notification_event_notification_event_recipient_path(@event, @record) }

  end

private

  def allowed_params
    groupings = [:notification_event_recipient]

    super(groupings, params)
  end


end
