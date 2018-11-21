class Admin::SalesReps::PartnersController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  def set_record
    @record = SalesRepPartner.find(params[:id])
  end

  def show

  end

  def new
    @record = SalesRepPartner.new()
    @record.sales_rep = @rep
  end

  def create

    form = Forms::AdminSalesRepPartner.new(@rep, current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add partner to sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to add partner to sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New partner has been associated with this sales rep."
    render :json => {success: true, redirect: admin_sales_rep_path(@rep) }
    return

  end

  def update
    raise "Controller updates are not supported for sales rep partners. Remove and re-add new partnership instead."
  end

  def delete
    # Unique case
    @record = SalesRepPartner.where(partner_id: params[:id], sales_rep_id: @rep.id).first

    if @record
      related_record = SalesRepPartner.where(partner_id: @record.sales_rep_id, sales_rep_id: @record.partner_id).first
      @record.deleted!
      if related_record
        related_record.deleted!
      end

      flash[:alert] = "Sales rep partnership has been removed."
    else
      flash[:alert] = "Unable to remove sales rep partnership as it no longer exists."
    end
    render :json => {success: true, redirect: admin_sales_rep_path(@rep) }
  end

private

  def allowed_params
    groupings = [:sales_rep_partner]

    super(groupings, params)
  end


end
