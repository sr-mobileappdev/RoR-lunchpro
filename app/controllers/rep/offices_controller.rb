class Rep::OfficesController < ApplicationRepsController
  before_action :set_office, except: [:index, :search, :new, :create, :show_refer, :refer]
  before_action :set_appointment, only: [:cancel_reserve]
  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end

  def set_office
    @office = Office.where(id: params[:id]).first
    redirect_to "/404" if !@office || !@office.active? || !@office.activated?
  end
  def set_appointment
    @appointment = Appointment.where(id: params[:appointment_id]).first
  end

  # Post to get a list of offices matching certain criteria
  def search
    list_type = params[:list_type] || "offices"
    search_term = params[:searchTerm].present? ? params[:searchTerm] : nil
    locals = {}
    search_results_template = 'rep/offices/components/office_results'
    case list_type
      #searching all offices that don't belong to the sales rep, used when adding a new office
      when "all_offices"
        get_all_offices(search_term)
        search_results_template = 'rep/offices/components/new_office_results'
        @for_orders = params[:for_orders] if params[:for_orders].present?
        locals = {offices: @offices, show_in_modal: true}

      #searching my offices
      when "offices"
        get_my_offices(search_term)
        search_results_template = 'rep/offices/components/office_results'
        locals = {offices: @offices}

      #search providers
      when "providers"
        get_my_providers(search_term)
        search_results_template = 'rep/offices/components/provider_results'
        locals = {providers: @providers}

      #searching my offices for adding appointment view
      when "offices_appts"
        get_my_offices(search_term)
        search_results_template = 'rep/appointments/components/new_appointment_office_results'
        locals = {offices: @offices, new_offices: false}

      when "offices_orders"
        get_my_offices(search_term)
        search_results_template = 'rep/orders/components/new_order_office_results'
        locals = {offices: @offices}
      when "all_offices_orders"

      #searching all offices for adding appointment view, return immediately
      when "all_offices_appts"
        get_all_offices(search_term)
        search_results_template = 'rep/appointments/components/new_appointment_office_results'
        locals = {offices: @offices, show_in_modal: true, new_offices: true}

        render json: {
          templates: { targ__tab_new_office_results: (render_to_string :partial => search_results_template, :locals => locals, :layout => false, :formats => [:html]) }
        }
        return
    end

    if @xhr
      render json: {
                      templates: { targ__tab_results: (render_to_string :partial => search_results_template, :locals => locals, :layout => false, :formats => [:html]) }
                    }
    else
      get_my_offices
      render :index
    end

  end

  # List of reps offices
  def index
    list_type = params[:list_type] || "offices"

    #if office id is passed in as url param, check against current user's offices
    @office = params[:id] || nil
    @load_tab = params[:tab] || nil
    if @office && !current_user.sales_rep.offices_sales_reps.active.pluck(:office_id).include?(@office.to_i)
      @office = nil
    end

    case list_type
      when "offices"
        get_my_offices
      when "providers"
        get_my_providers
    end
    @office = @offices.first.id if @offices.any? && !@office
  end

  def edit
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/rep_edit_non_lp_office', :layout => false, :formats => [:html]) }
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    else
      get_my_offices
      render :index
    end
  end

  def update
    form = Forms::OfficesSalesRep.new(current_user, @office, current_user.sales_rep, params)

    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

     # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new office at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    flash[:success] = "Office has been updated!"
    redirect_to rep_offices_path(:id => @office.id)

  end

  # Individual office detail view
  def show
    @office_view = true
    @redirect_to = "office"
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'rep/offices/components/office_detail_modal', :layout => false, :formats => [:html]) }
      else
        if params[:new_office]
          @office_sales_rep = OfficesSalesRep.new()
          partial = 'rep/offices/components/new_office_detail'
        else
          partial = 'rep/offices/components/office_detail'
          partial = 'rep/offices/components/non_lp_office_detail' if @office.private__flag
          @office_sales_rep = OfficesSalesRep.where(:office_id => @office.id, :sales_rep_id => current_user.sales_rep.id, :status => 'active').first
        end

        render json: { href: rep_office_path(@office),
                        templates: {
                          targ__office_detail: (render_to_string :partial => partial, :layout => false, :formats => [:html])
                        }
                      }
      end
    else
      get_my_offices
      render :index
    end
  end

  def new
    @offices = []
    @office = Office.new(timezone: Constants::DEFAULT_TIMEZONE, internal: false)
    @sales_rep = current_user.sales_rep
    @selected_office = params[:id]
    @back = ""
    if params[:back].present?
      @back = params[:back]
    end

  end

  def add

    form = Forms::OfficesSalesRep.new(current_user, @office, current_user.sales_rep)

    success = form.add_office
    if success && form.errors.count == 0
      render json: {message: 'Success'}
    else
      raise "Failure in adding office: #{form.errors.join(', ')}"
    end

  end

  def create
    form = Forms::OfficesSalesRep.new(current_user, @office, current_user.sales_rep, params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

     # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new office at this time due to a server error.", errors: form.errors}, status: 500
      return
    end

    if params[:office][:office_poc].present? && params[:office][:office_poc].blank? != true
      if params[:office][:office_poc].include? ' '
        full_name = params[:office][:office_poc].split(" ")
        contact_first_name = full_name.first
        contact_last_name = full_name.last

        params_poc = ActionController::Parameters.new({
          office_poc: ActionController::Parameters.new({
                created_by_id: "",
                office_id: form.office.id,
                first_name: contact_first_name,
                last_name: contact_last_name,
                title: "",
                phone: form.office.phone,
                email: "",
                primary: "1"
            })
        })

        office_id = form.office.id 
        form = Forms::AdminOfficePoc.new(current_user, params_poc.permit!)

        unless form.valid?
          return
        end
    
        # Model validations & save
        unless form.save
          return
        end

        redirect_to finish_rep_office_path(id: office_id, type: 'create')
        return
      end
    end

    if params[:refer].present?
      render :json => {refer_success:true}
      return
    end
    if params[:for_orders].present?
      redirect_to set_delivery_rep_orders_path(office: form.office.id)
      return
    end
    redirect_to finish_rep_office_path(id: form.office.id, type: 'create')

  end

  #remove office from sales_rep list, deactivate association and any appointments/orders tied  to this office
  def remove
    office_sales_rep = OfficesSalesRep.where(:office_id => @office.id, :sales_rep_id => current_user.sales_rep.id).active.first
    form = Forms::OfficesSalesRep.new(current_user, @office, current_user.sales_rep, nil, office_sales_rep)
    unless form.remove_office
      flash[:success] = "Unable to remove office from your list due to a server error."
      render :json => {success: false, redirect: rep_offices_path} and return
    end
    flash[:success] = "Office has been removed from your list!"
    render :json => {success: true, redirect: rep_offices_path} and return
  end


  def reserve_slot
    @type = params[:type]

    date = Date.parse(params[:slot_date])
    slot_id = params[:slot_id]
    slot = AppointmentSlot.find(slot_id)

    rep = current_user.sales_rep
  
    appointment = Appointment.new(:sales_rep_id => rep.id, :office_id => @office.id, :appointment_slot_id => slot_id, :created_by_user_id => @modifier_id, :status => "active", :appointment_on => date,
                                  :starts_at => slot.starts_at, :ends_at => slot.ends_at, :origin => 'web')

    if @type == 'appt'
      if appointment.is_duplicate?
        render json: { 
          display_duplicate: true,
          office_id: @office.id,
          slot_id: slot_id,
          date: date
        } and return
      end
    end

    unless appointment.valid? && appointment.save && trigger_notifications([appointment])
        flash[:error] = appointment.errors.full_messages.first || "There was a problem processing your request. Please contact support@lunchpro.com."
        redirect_to request.referrer and return
    end


    office_slot = Views::Slot.new(date, slot, appointment)

    if @type == 'book_duplicate'
      render json: { book_duplicate: true,
              slot_id: slot_id,
              appt_id: appointment.id,
              href: rep_office_path(@office),
              template: (render_to_string :partial => 'rep/calendars/components/sales_rep_office_slot', locals: {office_slot: office_slot, user: current_user}, :layout => false, :formats => [:html])
            }  and return
    else
      render json: { trigger_booked_modal: true,
                    appt_id: appointment.id,
                    href: rep_office_path(@office),
                    template: (render_to_string :partial => 'rep/calendars/components/sales_rep_office_slot', locals: {office_slot: office_slot, user: current_user}, :layout => false, :formats => [:html])
                  }  and return
    end
  end

  def cancel_reserve
    sales_rep = current_user.sales_rep

    redirect_to request.referrer and return if !@appointment
    @appointment.update_attributes(cancelled_at: Time.now, status: "inactive", cancelled_by_id: @modifier_id)

    #if cancelling from the /review view, don't render office slot, redirect back to review
    if !params[:review]
      date = Date.parse(params[:slot_date])
      slot_id = params[:slot_id]
      slot = AppointmentSlot.find(slot_id)

      office_slot = Views::Slot.new(date, slot, nil)



      render json: { href: rep_office_path(@office),
                      template: (render_to_string :partial => 'rep/calendars/components/sales_rep_office_slot', locals: {office_slot: office_slot, user: current_user}, :layout => false, :formats => [:html])
                    }

    else
      path = review_rep_office_path(id: @office.id)
      if @office.appointments.where(:sales_rep_id => current_user.sales_rep.id, :status => 'pending').count == 0
        path = calendar_rep_office_path(@office)
      end
      render json: {success: true, redirect: path}
    end

  end

  def filter_slots

    start_date = Time.zone.now.to_date
    start_on_start_date = false
    if params[:start_date].present?
      # Start from a unique start date point
      start_date = Date.parse(params[:start_date])
      start_on_start_date = true
    end
    
    render json: { href: rep_office_path(@office),
      template: (render_to_string :partial => 'rep/calendars/components/slots',
      locals: {slot_manager: Views::OfficeAppointments.new(@office, calendar_range(start_date, start_on_start_date), current_user, params[:provider_ids])}, :layout => false, :formats => [:html])
    }

  end

  # Specific office calendar showing appointments available and specific to the logged in rep
  def calendar
    @start_date = params[:start]
  end

  # All office policies for this office
  def policies
    if @xhr
      if modal?
 #       render json: { html: (render_to_string :partial => 'rep/offices/components/office_detail_modal', :layout => false, :formats => [:html]) }
      else
        render json: {
                        templates: {
                          targ__office_policies: (render_to_string :partial => 'rep/offices/components/office_detail__policies', locals:{office: @office}, :layout => false, :formats => [:html])
                        }
                      }
      end
    else


    end

  end

  def finish

    @type = params[:type]
    form = Forms::FrontendAppointment.new(current_user, nil, nil, @modifier_id)
    case @type
    #standard finish, booking appts
    when 'appt'
      current_appts = current_user.sales_rep.recent_pending_appointments.where(:office_id => @office.id)
      if current_appts.count == 1
        @appointment = current_appts.first
      end
      triggerable_appointments = Appointment.where(id: current_appts.pluck(:id)) #Immutable list of these appointments, for triggering notifications

      duplicate_appts = form.confirm_appointments(current_appts)
      if duplicate_appts.any?
        redirect_to review_duplicates_rep_office_path(@office)
      elsif form.errors.any?
        flash[:error] = form.errors.first
        redirect_to request.referrer and return
      end
      trigger_notifications(triggerable_appointments)

    #finish when user chooses to book duplicate appts
    when 'book_duplicates'
      appointments = current_user.sales_rep.check_for_duplicate_appointments(@office.appointments.where(:status => 'pending', 
      :sales_rep_id => current_user.sales_rep.id).sort_by{|appt| appt.appointment_on})
      
      triggerable_appointments = Appointment.where(id: appointments.pluck(:id)) #Immutable list of these appointments, for triggering notifications

      form.confirm_appointments(appointments, true)
      if form.errors.any?
        flash[:error] = form.errors.first
        redirect_to request.referrer and return
      end
      trigger_notifications(triggerable_appointments)

    #finish when user decides to cancel the booking of duplicate appts
    when 'cancel'
      appointments = current_user.sales_rep.check_for_duplicate_appointments(@office.appointments.where(:status => 'pending', 
      :sales_rep_id => current_user.sales_rep.id).sort_by{|appt| appt.appointment_on})
    
      unless form.cancel_appointments(appointments)
        flash[:error] = form.errors.first
        redirect_to request.referrer and return
      end
    end
  end

  def review
    @appointments = @office.appointments.where(:status => 'pending', :sales_rep_id => current_user.sales_rep.id).sort_by{|appt| appt.appointment_on}
    @start_date = @appointments.last.appointment_on if @appointments.any?
    redirect_to calendar_rep_office_path(@office) if !@appointments.any?
  end

  def review_duplicates
    @appointments = current_user.sales_rep.check_for_duplicate_appointments(@office.appointments.where(:status => 'pending', 
      :sales_rep_id => current_user.sales_rep.id).sort_by{|appt| appt.appointment_on})
    redirect_to calendar_rep_office_path(@office) if !@appointments.any?
  end

  # Individual office about area
  def about

  end

  # Individual office appointments area
  def appointments

  end

  # Individual office notes
  def notes

  end

  def show_refer
    @office = Office.new(timezone: Constants::DEFAULT_TIMEZONE, :internal => false)
    @office_referral = OfficeReferral.new(:created_by_id => @modifier_id)
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/rep_refer_office', :layout => false, :formats => [:html]) }
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    end
    return
  end

  def refer
    #logic for sending referral, perhaps check if office has already been created

    referral = OfficeReferral.new(office_referral_params)


    unless referral.valid?
      render :json => {success: false, general_error: "Unable to refer office due to the following errors or notices:", errors: referral.errors.full_messages}, status: 500
      return
    end

    unless referral.save
      render :json => {success: false, general_error: "Unable to refer office due to the following errors or notices:", errors: referral.errors.full_messages}, status: 500
      return
    end

    if params[:save_office] == "1"
      render :json => {show_add_office: true, name: referral.name, referral_id: referral.id}
    else
      render :json => {show_add_office: false, refer_success: true }
    end

  end

  private
  def get_active_offices
    @offices = Office.where.not(id: current_user.sales_rep.offices_sales_reps.active.pluck(:office_id), internal: false).active.sort_by{|o| [(o.private__flag ? 1 : 0), o.name]}
  end

  def get_my_offices(search_term = nil)
    if search_term
      @offices = Managers::SearchManager.new(Office, search_term).results_for_rep_my_offices(current_user.sales_rep).sort_by{|o| [(o.private__flag ? 1 : 0), o.name]}
    else
      @offices = []
      @offices = current_user.sales_rep.active_offices.sort_by{|o| [(o.private__flag ? 1 : 0), o.name]}
    end
  end
  def get_my_providers(search_term = nil)
    if search_term
      @providers = Managers::SearchManager.new(Provider, search_term).results_for_rep_my_providers(current_user.sales_rep).sort_by{|p| p.last_name}
    else
      @providers = Provider.for_office_ids(current_user.sales_rep.active_offices.pluck(:id)).sort_by{|p| p.last_name}

    end
  end

  def get_all_offices(search_term)
  	if search_term.present? && search_term.length >= 3
	    @offices = Managers::SearchManager.new(Office, search_term).results_for_rep(current_user.sales_rep, true).sort_by{|o| [(o.private__flag ? 1 : 0), o.name]}
	else
		@offices = []
	end
  end

  # Return a future calendar range to show, based on current date
  def calendar_range(start_date = Date.beginning_of_week, start_on_start_date = false)
    if start_on_start_date

      #if office has appointments_until set, and it's before the end of the week. set end date to be appointments_until
      if @office.appointments_until && @office.appointments_until < start_date + 6.days
        start_date..@office.appointments_until
      else
        start_date..(start_date + 6.days).to_date
      end
    else
      Time.zone.now.to_date..(start_date + 6.days).to_date
    end
  end

  def trigger_notifications(appointments)
    appointments.each do |appointment|
      notifs = should_trigger_notifications(appointment)
      if notifs.count > 0
        Managers::NotificationManager.trigger_notifications(notifs, [appointment, appointment.office, appointment.sales_rep, appointment.appointment_slot])
      end
    end
  end

  def should_trigger_notifications(appointment)
    if appointment.sales_rep
      if appointment.sales_rep.user
        [202] # Rep books appointment
      else
        [201] # Rep books appointment (no LP account)
      end
    elsif appointment.sales_rep.nil?
      [117] # Office books internal appointment
    else
      []
    end
  end

  private

  def office_referral_params
    params.require(:office_referral).permit(:name, :phone, :email, :created_by_id)
  end

end
