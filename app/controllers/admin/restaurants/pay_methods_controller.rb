class Admin::Restaurants::PayMethodsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_record
    @bank_account = BankAccount.find(params[:id])
  end

  def set_bank_account_manager
    @bank_account_manager = Managers::BankAccountManager.new(@restaurant, nil, current_user)
  end

  def index

  end

  def new
    @bank_account = BankAccount.new(created_by_id: current_user.id, restaurant_id: @restaurant.id)

  end

  def show

  end


  def create

    if @restaurant.bank_accounts.active.any?
      @old_account = @restaurant.bank_accounts.active.first
    end

    form = Forms::AdminBankAccount.new(current_user, allowed_params)
     unless form.valid?
       render :json => {success: false, general_error: "Unable to create new bank account, due to the following errors or notices:", errors: form.errors}, status: 500
       return
     end

     # Model validations & save
     unless form.save
       render :json => {success: false, general_error: "Unable to create new bank account at this time due to a server error.", errors: []}, status: 500
       return
     end

     @old_account.update_attributes(status: 'deleted') if @old_account

     return_path = admin_restaurant_pay_methods_path(@restaurant)

     flash[:notice] = "'#{form.bank_account.display_name}' has been created as a new bank account for #{@restaurant.name}."
     if params[:wizard] == 'true'
       render :json => {success: true, reload: true}
       return
     else
       render :json => {success: true, redirect: return_path }
       return
     end

  end

  def update

    form = Forms::AdminBankAccount.new(current_user, allowed_params, @bank_account)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update bank account due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update bank account at this time due to a server error.", errors: []}, status: 500
      return
    end

    return_path = admin_restaurant_pay_methods_path(@restaurant)

    flash[:notice] = "Bank account has been updated."
    render :json => {success: true, redirect: return_path }
    return

  end

  def delete
    @bank_account.update_attributes(:status => 'deleted')

    flash[:alert] = "Payment method has been deleted."
    unless @bank_account.deleted?
      render :json => { success: false, general_error: "This bank account could not be deleted for the following reason(s):", errors: @bank_account.errors.full_messages}, status: 500
      return
    end

    Managers::NotificationManager.trigger_notifications([302], [@restaurant], {poc: current_user.poc_info})

    if params[:wizard] == 'true'
      flash[:notice] = "Bank account has been deleted"
      render :json => {success: true, reload: true}
      return
    else
      flash[:notice] = "Bank account has been deleted"
      redirect_to admin_restaurant_pay_methods_path
    end

  end

private

  def allowed_params
    groupings = [:bank_account]

    super(groupings, params)
  end

end
