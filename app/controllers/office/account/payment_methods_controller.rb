class Office::Account::PaymentMethodsController < ApplicationOfficesController

  before_action :set_office
  before_action :set_user

  before_action :set_record, only: [:show, :edit, :update, :delete, :set_default]
  before_action :set_payment_manager, except: [:index, :show, :new]


  def set_office
    @office = current_user.user_office.office
  end

  def set_user
    @user = current_user
  end

  def set_record
    @record = PaymentMethod.find(params[:id])
  end

  def set_payment_manager
    @payment_manager = Managers::PaymentManager.new(@user, nil, @record)
  end

  def index
    redirect_to new_office_account_payment_method_path if !current_user.payment_methods.active.any?
    @payment_methods = current_user.non_default_payment_methods
    @default_payment_method = current_user.default_payment_method
  end

  def update
    unless @payment_manager.update_stripe_card(payment_params)
      render :json => {success: false, general_error: "Unable to update payment method due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end

    unless @record.update_attributes!(payment_params)
      render :json => {success: false, general_error: "Unable to update payment method due to the following errors or notices:", errors: @record.errors.full_messages}, status: 500
      return
    end
    flash[:success] = "Payment method has been updated!"
    redirect_to office_account_payment_methods_path
  end

  def new
    @record = PaymentMethod.new
    @payment_manager = Managers::PaymentManager.new(@user, nil, @record)
  end

  def edit

  end

  def create
    unless @payment_manager.create_stripe_card(params[:card_token], params[:default], params, false, "active")
      render :json => {success: false, general_error: "Unable to add payment method due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end

    flash[:success] = "New payment method has been created!"
    redirect_to office_account_payment_methods_path
    return

  end

  def delete
    new_default = nil
    if @record.default && @user.payment_methods.active.count > 1     
      new_default = @user.non_default_payment_methods.first
    end

    unless @record.update_attributes(:status => 'inactive') 
      message = @record.errors.full_messages.first
      flash[:error] = message || "Unable to delete payment method due to a server error."
      render :json => {success: true, redirect: office_account_payment_methods_path} and return
    end

    @payment_manager.delete_stripe_card(new_default)

    flash[:success] = "Payment method has been deleted!"
    render :json => {success: true, redirect: office_account_payment_methods_path}
    return
  end

  def set_default
    unless @payment_manager.set_default_payment_method
      render :json => {success: false, general_error: "Unable to delete payment method due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end

    flash[:success] = "Payment method has been set to the default!"
    redirect_to office_account_payment_methods_path
    return
  end

private

  def payment_params
    params.permit(:name, :exp_month, :exp_year, :address_line1, :address_line2, :address_city, :address_state, :address_zip)
  end

end
