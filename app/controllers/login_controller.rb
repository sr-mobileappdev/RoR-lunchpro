class LoginController < ApplicationController

  def index
    # This is here to handle potential re-routing of login depending on circumstances
    redirect_to new_user_session_path
  end

end
