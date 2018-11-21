class Admin::SalesReps::ContactsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  def set_record
    if params[:contact_type].present?
      if params[:contact_type] == "email"
        @record = SalesRepEmail.find(params[:id])
      elsif params[:contact_type] == "phone"
        @record = SalesRepPhone.find(params[:id])
      end
    else
      flash[:alert] = "Unable to find contact details for this sales rep"
      redirect_to admin_sales_rep_path(@rep)
    end
  end

  def show

  end

  def new

    template = ""
    if params[:contact_type] == "email"
      @record = SalesRepEmail.new()
      template = "new_email"
    elsif params[:contact_type] == "phone"
      @record = SalesRepPhone.new()
      template = "new_phone"
    end

    render template

  end

  def create

    form = Forms::AdminSalesRepContact.new(@rep, current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add contact info to sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to add contact info to sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New contact details added to sales rep."
    render :json => {success: true, redirect: admin_sales_rep_path(@rep) }
    return

  end

  def edit_preferences
    @user_notification_prefs = @rep.user.user_notification_prefs.active.first
    if !@user_notification_prefs
      @user_notification_prefs = UserNotificationPref.new(:user_id => @rep.user.id, :status => 'active',
        :last_updated_by_id => current_user.id, :via_email => {}, :via_sms => {})
    end
  end

  def update_preferences
    user_notification_prefs = @rep.user.user_notification_prefs.active.first
    if !user_notification_prefs.present?
      user_notification_prefs = UserNotificationPref.new(allowed_notification_prefs_params)
    else
      user_notification_prefs.assign_attributes(allowed_notification_prefs_params)
    end
    user_notification_prefs.save!


    flash[:success] = "Notification Preferences have been updated!"
    redirect_to admin_sales_rep_contacts_path(@rep)
  end

  def update
    raise "Controller updates are not supported for sales rep partners. Remove and re-add new partnership instead."
  end

  def delete
    @record.update(:status => 'deleted')
    render :json => {success: true, redirect: admin_sales_rep_contacts_path(@rep) }
  end

private

  def allowed_notification_prefs_params
    params.require(:user_notification_pref).permit(:user_id, :status, :last_updated_by_id, via_email: {}, via_sms: {})
  end

  def allowed_params
    groupings = [:sales_rep_phone, :sales_rep_email]

    super(groupings, params)
  end


end
