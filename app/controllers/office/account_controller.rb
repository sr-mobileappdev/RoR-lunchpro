class Office::AccountController < ApplicationOfficesController

  before_action :set_office
  before_action :set_user

  def set_office
    @office = current_user.user_office.office
  end

  def set_user
    @user = current_user
  end

  def index
  end

  # individual calendar for a specific office
  def show

  end
  
  # The current overall calendar for a single rep, across all offices
  def change_password
  end

  def end_impersonation
    impersonator = User.where(:id => session[:impersonator_id]).first
    return if !impersonator
    sign_in(:user, impersonator)
    redirect_to session[:impersonator_return_url]
  end
  
  def update_password
    form = Forms::User.new(@user, user_params, current_user)

    unless form.change_password?
      render :json => {success: false, general_error: "Unable to update sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end
    sign_in(current_user, :bypass => true)
    # Model validations & save
    flash[:success] = "Password Changed successfully!"
    redirect_to office_account_path
    return

  end



  def show_delete_account
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/rep_delete', :layout => false, :formats => [:html]) }
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    else
      get_my_offices
      render :index
    end
  end

  def delete_account
    form = Forms::User.new(current_user, current_user)
    unless form.delete_account
      flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
    end
    flash[:success] = "Account was successfully deleted!"
    sign_out current_user
    redirect_to new_session_path('user')
  end

private

  def user_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
