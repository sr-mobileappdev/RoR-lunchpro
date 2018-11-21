class Admin::Offices::ProvidersController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def set_record
    @record = Provider.find(params[:id])
  end

  def show

  end

  def new
    @record = OfficesProvider.new(provider: Provider.new, office: @office)

  end

  def create

    form = Forms::AdminOfficesProvider.new(@office, current_user, allowed_params, nil, params[:set_availability])
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add provider to office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to add provider to office at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New provider has been added to this office."
    redirect_to = admin_office_providers_path(@office)
    redirect_to = admin_office_provider_path(@office, form.provider.id) if !params[:set_availability] || params[:set_availability] == "0"
    render :json => {success: true, redirect: redirect_to }
    return

  end

  def update
    form = Forms::AdminOfficesProvider.new(@office, current_user, allowed_params, @record, params[:set_availability])
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update provider due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update provider at this time due to a server error.", errors: []}, status: 500
      return
    end


    flash[:notice] = "Provider details have been updated."
    render :json => {success: true, redirect: admin_office_providers_path(@office) }
    return

  end

  def delete

    #set office provider to deleted
    @record.update_attributes!(status: 'deleted')
    flash[:alert] = "Office Provider has been deleted from the LunchPro system."
    render :json => {success: true, redirect: admin_office_providers_path(@office) }

  end

private

  def allowed_params
    groupings = [:offices_provider, :provider, :diet_restrictions]

    super(groupings, params)
  end

end
