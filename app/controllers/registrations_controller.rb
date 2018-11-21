# app/controllers/registrations_controller.rb
class RegistrationsController < Devise::RegistrationsController

  def new
    @user = User.new(:space => "space_sales_rep")
    @companies = Company.active.select(:id, :name).to_json
  end

  def create
    form = Forms::User.new(nil, user_params, nil)
    unless form.valid_for_registration?
      render :json => {success: false, general_error: "Unable to complete registration due to the following errors:", errors: form.errors}, status: 500
      return
    end
    unless form.register_rep
      render :json => {success: false, general_error: "Unable to complete registration due to the following errors:", errors: [form.errors]}, status: 500
      return
    end
    render :json => {show_registration_success: true}
  end

  def update
    super
  end


  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :space, :first_name, :last_name, :email, :primary_phone,
      sales_rep_attributes: [:company_id, :phone_number, :user_id, :address_line1, :address_line2, :city, :state, :postal_code])
  end
end 