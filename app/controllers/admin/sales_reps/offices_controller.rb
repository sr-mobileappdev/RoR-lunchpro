class Admin::SalesReps::OfficesController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  def set_record
    @record = OfficesSalesRep.find(params[:id])
  end

  def show

  end

  def new
    @record = OfficesSalesRep.new()
    @record.sales_rep = @rep
  end

  def create

    form = Forms::AdminOfficesSalesRep.new(@rep, current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add office to sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to add office to sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New office has been assigned to this sales rep."
    render :json => {success: true, redirect: admin_sales_rep_path(@rep) }
    return

  end

  def update

    form = Forms::AdminOfficesSalesRep.new(@rep, current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update office at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Sales rep office details have been updated."
    render :json => {success: true, redirect: admin_sales_rep_office_path(@rep, form.offices_sales_rep) }
    return

  end

private

  def allowed_params
    groupings = [:offices_sales_rep]

    super(groupings, params)
  end


end
