class Office::PreferencesController < ApplicationOfficesController
  before_action :set_office

  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end

  def index
redirect_to current_office_calendars_path
  end

  def show
redirect_to current_office_calendars_path
  end

  def appointments_until
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/appointments_until', :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  def create

  end

  #policies tab
  def policies

  end

  #directory tab
  def directory
    @sales_reps = @office.active_reps
  end

  def notification_preferences
    @user_notification_prefs = current_user.user_notification_prefs.active.first
    if !@user_notification_prefs
      @user_notification_prefs = UserNotificationPref.new(:user_id => current_user.id, :status => 'active', 
        :last_updated_by_id => @modifier_id, :via_email => {}, :via_sms => {})
    end
  end

  def update_notification_preferences
    user_notification_prefs = current_user.user_notification_prefs.active.first
    if !user_notification_prefs.present?
      user_notification_prefs = UserNotificationPref.new(allowed_notification_prefs_params)
    else
      user_notification_prefs.assign_attributes(allowed_notification_prefs_params)
    end
    user_notification_prefs.save!


    flash[:success] = "Notification Preferences have been updated!"
    redirect_to notification_preferences_office_preferences_path
  end

  def show_rep
    @sales_rep = SalesRep.find(params[:sales_rep_id]) if params[:sales_rep_id].present?
    @office_sales_rep = @sales_rep.offices_sales_reps.where(:office_id => @office, :status => 'active').first
    @future_appointments = @sales_rep.appointments.
                              where(:status => 'active', :office_id => @office.id).
                              where("appointment_on > ?", Time.now.to_date).
                              order("appointment_on asc")

     @past_appointments = @sales_rep.appointments.
                              where(:status => 'active', :office_id => @office.id).
                              where("appointment_on < ?", Time.now.to_date).exists?



    if @xhr
      if modal? && @sales_rep
        @outstanding_orders = @sales_rep.orders.select{|order| order.active? && !order.cancellable?}.any?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/sales_reps/om_sales_rep_detail', :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  def show_rep_sample
    sales_rep = SalesRep.find(params[:sales_rep_id]) if params[:sales_rep_id].present?
    return if !sales_rep
    sales_rep_drugs = Drug.find(sales_rep.drugs.pluck(:drug_id)).to_json
    office_sales_rep = sales_rep.offices_sales_reps.where(:office_id => @office, :status => 'active').first

    appointment = Appointment.new(:office_id => @office.id, :status => 'draft', :sales_rep_id => sales_rep.id, :created_by_user_id => @modifier_id, :origin => 'web')
    if @xhr
      if modal? && sales_rep
        render json: { html: (render_to_string :partial => 'shared/modals/offices/sales_reps/om_sales_rep_request_sample', locals: {sales_rep: sales_rep,
          sales_rep_drugs: sales_rep_drugs, office_sales_rep: office_sales_rep, appointment: appointment}, :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  def search
    list_type = params[:list_type] || "all_reps"
    search_term = params[:searchTerm].present? ? params[:searchTerm] : nil
    locals = {}
    search_results_template = 'office/preferences/components/rep_results'
    case list_type
      #searching all offices that don't belong to the sales rep, used when adding a new office
    when "all_reps"
      get_all_reps(search_term)
      locals = {sales_reps: @sales_reps}
    end

    render json: {
                    templates: { targ__rep_results: (render_to_string :partial => search_results_template, :locals => locals, :layout => false, :formats => [:html]) }
                  }

  end

  def rep_past_appointments
    @sales_rep = SalesRep.find(params[:sales_rep_id]) if params[:sales_rep_id].present?
    @past_appointments = @sales_rep.appointments.
                              where(:status => 'active', :office_id => @office.id).
                              where("appointment_on < ?", Time.now.to_date).
                              order("appointment_on desc")

    if @xhr
      if modal? && @sales_rep
        render json: { html: (render_to_string :partial => 'shared/modals/offices/sales_reps/om_sales_rep_past_appointments', :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end                             
  end
  
  #change password form
  def change_password

  end
  
  #trigger either least fav restaurants or diet restrictions modal
  def policies_modal
    @restaurants = Restaurant.active.select(:id, :name).to_json

    #build empty diet_restrictions_offices that office currently doesn't have
    DietRestriction.where(:status => 'active').where.not(:id => @office.diet_restrictions_offices.pluck(:diet_restriction_id)).each do |restrict|
      @office.diet_restrictions_offices.build(:diet_restriction_id => restrict.id, :_destroy => true)
    end
    unless params[:type].present?
      raise "Must pass type parameter to determine which modal to trigger"
    end
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/' + params[:type], :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  def update
    form = Forms::OfficeManagers::OmOffice.new(current_user, office_params, @office)
    if params[:office][:office_restaurant_exclusions]
      unless form.update_restaurant_exclusions
        render :json => {success: false, general_error: "Unable to update office due to the following errors or notices:", errors: form.errors, show_bottom: true}, status: 500
        return
      end
    else
      unless form.valid?
        if params[:office][:appointments_until].present?
          render :json => {success: false, general_error: "Unable to update office due to the following errors or notices:", 
            errors: form.errors, show_bottom: true, disable_save: true}, status: 500
        else
          render :json => {success: false, general_error: "Unable to update office due to the following errors or notices:", errors: form.errors, show_bottom: true}, status: 500
        end
        return
      end

       # Model validations & save
      unless form.save
        render :json => {success: false, general_error: "Unable to update office at this time due to a server error.", errors: form.errors, show_bottom: true}, status: 500
        return
      end
    end
    if params[:office][:appointments_until].present?
      flash[:success] = "Calendar has been updated!"
    elsif params[:office][:offices_sales_reps_attributes].present?
      flash[:success] = "Sales Rep information has been updated!"
    else
      flash[:success] = "Office has been updated!"
    end
    if params[:redirect_to].present?
      redirect_to_tab(params[:redirect_to])
    else
      redirect_to office_account_path
    end
  end


  def update_exclusions
    unless params[:office].present?
      render :json => {success: false, general_error: "You must select at least one excluded dates range!", errors: []}, status: 500
      return
    end
    unless @office.update_attributes(office_params)
      render :json => {success: false, general_error: "Unable to update office exclusion date due to the following errors or notices:", errors: @office.errors.full_messages}, status: 500
      return
    end
    flash[:success] = "Calendar has been updated!"
    redirect_to current_office_calendars_path
  end
  
  private
    def get_all_reps(search_term)
      @sales_reps = Managers::SearchManager.new(SalesRep, search_term).om_sales_rep_results(@office.id, @office.active_reps.pluck(:id))
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_office
      @office = current_user.user_office.office
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def office_params
      params.require(:office).permit(:appointments_until, :phone, :total_staff_count, :office_policy, :delivery_instructions, :office_restaurant_exclusions, :name, :timezone, :address_line1, :address_line2, :city, :state, :postal_code, office_exclude_dates_attributes: [:id, :starts_at, :ends_at, :office_id, :_destroy], 
        office_pocs_attributes: [:id, :first_name, :last_name, :office_id, :phone, :email, :primary, :status, :created_by_id],
        diet_restrictions_offices_attributes: [:id, :diet_restriction_id, :staff_count, :office_id, :_destroy],
        office_restaurant_exclusions_attributes: [:id, :office_id, :restaurant_id, :_destroy],
        offices_sales_reps_attributes: [:id, :office_notes, :listed_type])
    end

    def allowed_notification_prefs_params
      params.require(:user_notification_pref).permit(:user_id, :status, :last_updated_by_id, via_email: {}, via_sms: {})
    end
end
