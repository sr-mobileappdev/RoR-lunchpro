class Rep::Profile::PaymentMethodsController < ApplicationRepsController
  before_action :set_rep
  before_action :set_record, only: [:show, :edit, :update, :delete, :set_default]
  before_action :set_payment_manager, except: [:index, :show, :new]

  def set_rep
    @sales_rep = current_user.sales_rep
  end

  def set_record    
    @record = PaymentMethod.where(id: params[:id]).first
    redirect_to "/404" if !@record || !@record.user == current_user
  end

  def set_payment_manager
    @payment_manager = Managers::PaymentManager.new(@sales_rep.user, nil, @record)
  end

  def show
    redirect_to current_rep_calendars_path
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
    redirect_to rep_profile_index_path(tab: "financial_info")
  end

  def new
    @record = PaymentMethod.new
    @payment_manager = Managers::PaymentManager.new(@sales_rep.user, nil, @record)
    if @xhr
      render json: {
        templates: {
          targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_new_payment', :layout => false, :formats => [:html])
        }
      }
    else
      redirect_to "/404"
    end
  end

  def edit
    @record = PaymentMethod.where(:id => params[:id]).first
    unless @record && current_user.payment_methods.pluck(:id).include?(@record.id)
      redirect_to rep_profile_index_path(tab: "financial_info")
    end
    if @xhr
      render json: {
        templates: {
          targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_edit_payment', :layout => false, :formats => [:html])
        }
      }
    else
      redirect_to "/404"
    end
  end

  def create
    unless @payment_manager.create_stripe_card(params[:card_token], params[:default], params, false, "active")
      render :json => {success: false, general_error: "Unable to add payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end

    flash[:success] = "New payment method has been created!"
    redirect_to rep_profile_index_path(tab: "financial_info")
    return

  end

  def delete

    new_default = nil
    if @record.default && @sales_rep.user.payment_methods.active.count > 1     
      new_default = @sales_rep.user.non_default_payment_methods.first
    end

    unless @record.update_attributes(:status => 'inactive') 
      message = @record.errors.full_messages.first
      flash[:error] = message || "Unable to delete payment method due to a server error."
      render :json => {success: true, redirect: '/rep/profile?tab=payment_method'} and return
    end

    @payment_manager.delete_stripe_card(new_default)

    flash[:success] = "Payment method has been deleted!"
    redirect_to rep_profile_index_path(tab: "financial_info")
    return
  end

  def set_default
    unless @payment_manager.set_default_payment_method
      render :json => {success: false, general_error: "Unable to delete payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
      return
    end

    flash[:success] = "Payment method has been set to the default!"
    redirect_to rep_profile_index_path(tab: "financial_info")
    return
  end

private

  def payment_params
    params.permit(:name, :exp_month, :exp_year, :address_line1, :address_line2, :address_city, :address_state, :address_zip, :nickname)
  end

  def allowed_params
    params.require(:payment_method).permit(:name, :exp_month, :exp_year, :address_line1, :address_line2, :address_city, :address_state, :address_zip, :nickname)
  end
end
