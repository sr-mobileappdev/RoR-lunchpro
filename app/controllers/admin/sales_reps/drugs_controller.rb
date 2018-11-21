class Admin::SalesReps::DrugsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  def set_record
    @record = DrugsSalesRep.find(params[:id])
  end

  def show

  end

  def new
    @record = DrugsSalesRep.new()
    @record.sales_rep = @rep
  end

  def create
    form = Forms::AdminDrugSalesRep.new(@rep, current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add drug to sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to add drug to sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New represented drug has been associated with this sales rep."
    render :json => {success: true, redirect: admin_sales_rep_path(@rep) }
    return

  end

  def update
    raise "Controller updates are not supported for sales rep drugs. Remove and re-add drug instead."
  end

  def delete
    @record = DrugsSalesRep.where(sales_rep_id: @rep.id, drug_id: params[:id], status: 'active').first

    if @record
      @record.deleted!
      flash[:alert] = "Drug representation has been removed."
    else
      flash[:alert] = "Unable to remove drug representation as it no longer exists."
    end
    render :json => {success: true, redirect: admin_sales_rep_path(@rep) }
  end

private

  def allowed_params
    groupings = [:drugs_sales_rep]

    super(groupings, params)
  end


end
