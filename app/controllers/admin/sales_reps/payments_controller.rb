class Admin::SalesReps::PaymentsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]
  before_action :set_payment_manager, except: [:index, :show, :new]

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  def set_record
    @record = PaymentMethod.find(params[:id])
  end

  def set_payment_manager
    @payment_manager = Managers::PaymentManager.new(@rep.user, nil, @record)
  end

  def show

  end

  def new
    @record = PaymentMethod.new
    @payment_manager = Managers::PaymentManager.new(@rep.user, nil, @record)
  end

  def edit
    
  end

  def update
    unless @payment_manager.update_stripe_card(params)
      render :json => {success: false, general_error: "Unable to add payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end

    @record.update_attributes(payment_params)
    flash[:notice] = "Payment method has been updated."
    render :json => {success: true, redirect: admin_sales_rep_payments_path(@rep)}
    return
  end

  def create
    #initialize payment manager, which sets the current stripe user or creates one if it doesnt exist, then create stripe card
    unless @payment_manager.create_stripe_card(params[:card_token], params[:default], params, false, "active")
      render :json => {success: false, general_error: "Unable to add payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end

    flash[:notice] = "New payment method has been assigned to this sales rep."
    render :json => {success: true, redirect: admin_sales_rep_payments_path(@rep)}
    return
  end

  def delete
    new_default = nil

    @record.update_attributes(:status => 'inactive')
    

    unless @payment_manager.delete_stripe_card(new_default)
      render :json => {success: false, general_error: "Unable to delete payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end


    flash[:alert] = "Payment method has been deleted."
    render :json => {success: true, redirect: admin_sales_rep_payments_path(@rep)}
    return

  end

private

  def payment_params
    params.permit(:name, :exp_month, :exp_year, :address_line1, :address_line2, :address_city, :address_state, :address_zip)
  end


end
