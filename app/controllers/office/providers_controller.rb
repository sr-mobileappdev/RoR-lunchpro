class Office::ProvidersController < ApplicationOfficesController

  before_action :set_office
  before_action :set_provider, except: [:new, :index, :create, :specialties]

  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end

  def set_office
    @office = current_user.user_office.office
  end

  def set_provider
    @provider = Provider.find(params[:id])
  end

  def index
    
  end

  def new
    partial = "shared/modals/offices/providers/om_new_provider"

    @provider = Provider.new(:status => 'active')
    #loop through each day of week in the enum
    Provider.day_of_weeks.each do |key, value|
      #build new availability to be used in the form
      @provider.provider_availabilities.build(:status =>'active', :day_of_week => key, :_destroy => true, :created_by_id => @modifier_id)
    end
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => partial, :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  def specialties
    render json: {
      specialties: Provider.specialties
    }
  end

  def show
    partial = "shared/modals/offices/providers/om_existing_provider"

    #loop through each day of week in the enum
    Provider.day_of_weeks.each do |key, value|
      #if an existing active availability is present for this provider, skip, else
      #build new availability to be used in the form
      avail = @provider.provider_availabilities.where(:day_of_week => key, :status => 'active').first
      if avail.present?
      else
        @provider.provider_availabilities.build(:status =>'active', :day_of_week => key, :_destroy => true, :created_by_id => @modifier_id)
      end
    end
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => partial, :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  def exclude_dates
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/providers/om_provider_exclude_date', :layout => false, :formats => [:html])}
        return
      else
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end
  end

  def create
    form = Forms::OfficeManagers::OmProvider.new(current_user, provider_params, nil, @office, params[:set_availability])
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update provider due to the following errors or notices:", errors: form.errors, show_bottom: true}, status: 500
      return
    end

     # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update provider at this time due to a server error.", errors: form.errors, show_bottom: true}, status: 500
      return
    end

    Managers::NotificationManager.trigger_notifications([115], [@office], {related_sales_reps: @office.active_reps(true)}) 
    flash[:success] = "Provider has been created!"
    redirect_to office_providers_path
  end

  def remove
    @provider.update(:status => 'deleted')
    @provider.provider_availabilities.each do |avail|
      avail.update(:status => 'deleted')
    end
    flash[:success] = "Provider has been removed from this office!"
    redirect_to providers_office_preferences_path
  end

  def update    
    form = Forms::OfficeManagers::OmProvider.new(current_user, provider_params, @provider, @office, params[:set_availability])
    
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update provider due to the following errors or notices:", errors: form.errors, show_bottom: true}, status: 500
      return
    end

     # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update provider at this time due to a server error.", errors: form.errors, show_bottom: true}, status: 500
      return
    end
    flash[:success] = "Provider has been updated!"
    redirect_to office_providers_path
  end
  # The current overall calendar for a single rep, across all offices
  def current

  end

  private
  def provider_params
    params.require(:provider).permit(:first_name, :last_name, :title, :specialties, provider_exclude_dates_attributes: [:id, :provider_id, :starts_at, :ends_at, :_destroy],
      provider_availabilities_attributes: [:id, :created_by_id, :day_of_week, :provider_id, :starts_at, :ends_at, :status, :_destroy])
  end

end
