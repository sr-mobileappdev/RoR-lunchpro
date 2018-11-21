class Office::PasscodeController < ApplicationOfficesController

  before_action :set_office

  def set_office
    @office = current_user.user_office.office
  end

  def index
    
  end

  def new
    redirect_to office_passcode_path and return if !@office.passcode.present? || !session[:change_passcode_initialized]
  end
  #used when a user 'excludes' an open appt slot
  def create

  end

  def update
    passcode = params[:office][:passcode].sum.to_i
    unless passcode.digits.count == 4
      render :json => {success: false, general_error: "You must provide a 4 digit passcode.", clear_passcode: true}, status: 500
      return
    end
    crypt = ActiveSupport::MessageEncryptor.new(ENV['PASSCODE_KEY'])
    encrypted_data = crypt.decrypt_and_verify(@office.passcode)
    if encrypted_data == passcode
      @office.update(:passcode_active => true)
    else
      render :json => {success: false, general_error: "Passcodes do not match!", clear_passcode: true}, status: 500
      return
    end
    session.delete(:passcode_initialized)
    session.delete(:new_passcode_initialized)
    session.delete(:change_passcode_initialized)
    #Managers::NotificationManager.trigger_notifications([108], [@office]) 
    redirect_to complete_office_passcode_path
    return
  end

  def verify
    redirect_to office_passcode_path and return if !@office.passcode.present? || !(session[:passcode_initialized] || session[:new_passcode_initialized])
    @change_passcode = session[:new_passcode_initialized]
  end

  def initialize_passcode
    passcode = params[:office][:passcode].sum.to_i
    unless passcode.digits.count == 4
      render :json => {success: false, general_error: "You must provide a 4 digit passcode.", clear_passcode: true}, status: 500
      return
    end
    if !params[:change_passcode].present?
      crypt = ActiveSupport::MessageEncryptor.new(ENV['PASSCODE_KEY'])
      encrypted_data = crypt.encrypt_and_sign(passcode)
      @office.update(:passcode => encrypted_data)
      session[:passcode_initialized] = true
      redirect_to verify_office_passcode_path
      return
    else
    crypt = ActiveSupport::MessageEncryptor.new(ENV['PASSCODE_KEY'])
    encrypted_data = crypt.decrypt_and_verify(@office.passcode)
    unless encrypted_data == passcode
        render :json => {success: false, general_error: "Passcodes do not match!", clear_passcode: true}, status: 500
        return
      end
      session[:change_passcode_initialized] = true
      redirect_to new_office_passcode_path
      return
    end
  end

  def initialize_new_passcode
    passcode = params[:office][:passcode].sum.to_i
    unless passcode.digits.count == 4
      render :json => {success: false, general_error: "You must provide a 4 digit passcode.", clear_passcode: true}, status: 500
      return
    end
    crypt = ActiveSupport::MessageEncryptor.new(ENV['PASSCODE_KEY'])
    encrypted_data = crypt.encrypt_and_sign(passcode)
    @office.update(:passcode => encrypted_data)
    session[:new_passcode_initialized] = true
    redirect_to verify_office_passcode_path
    return
  end

  def deactivate
    session.delete(:passcode_initialized)
    @office.update(:passcode_active => false)
    flash[:success] = "Passcode has been deactivated!"
    redirect_to office_passcode_path
  end

  def activate 
    @office.update(:passcode_active => true)
    flash[:success] = "Passcode has been activated!"
    redirect_to office_passcode_path
  end

  def complete
    redirect_to office_passcode_path if !@office.passcode_active?
  end

end
