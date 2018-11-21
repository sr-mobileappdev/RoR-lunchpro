class Admin::Offices::SalesRepsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def set_record
    @record = OfficesSalesRep.find(params[:id])
  end

  def show

  end

  def new
    @record = OfficesSalesRep.new()
    @record.office = @office
  end

  def create

    form = Forms::AdminOfficesSalesRep.new(@office, current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add sales rep to office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to add sales rep to office at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New sales rep has been assigned to this office."
    render :json => {success: true, redirect: admin_office_path(@office) }
    return

  end

  def update

    form = Forms::AdminOfficesSalesRep.new(@office, current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Sales rep office details have been updated."
    render :json => {success: true, redirect: admin_office_sales_rep_path(@office, form.offices_sales_rep) }
    return

  end

  def delete

    #grab officesalesrep
    @record = OfficesSalesRep.where(:office_id => @office.id, :sales_rep_id => params[:id], :status => 'active').first
    @record.update_attributes!(status: 'inactive')
    flash[:alert] = "Sales Rep has been removed from this office."
    render :json => {success: true, redirect: admin_office_providers_path(@office) }

  end

private

  def allowed_params
    groupings = [:offices_sales_rep]

    super(groupings, params)
  end

end
