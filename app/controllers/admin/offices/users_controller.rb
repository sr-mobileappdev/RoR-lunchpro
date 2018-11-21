class Admin::Offices::UsersController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def set_record
    @record = User.find(params[:id])
    @user_office_record = UserOffice.where(:user_id => params[:id], :office_id => @office.id).first
  end

  def show

  end

  def new
    @record = UserOffice.new()
    @record.office = @office
    @record.user = User.new()
  end


  def create

    form = Forms::AdminUserOffice.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add office user to office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save_and_invite
      render :json => {success: false, general_error: "Unable to office user to office at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New office user has been assigned to this office."
    render :json => {success: true, redirect: admin_office_path(@office) }
    return

  end

  def update

    form = Forms::AdminUserOffice.new(current_user, allowed_params, @record, @record.user)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "User details have been updated."
    render :json => {success: true, redirect: admin_office_path(@office) }
    return

  end

  def delete
    #set office user to deleted
    @record.update_attributes!(status: 'deleted')
    @user_office_record.update_attributes!(status: 'deleted')
    flash[:alert] = "Office user has been deleted from the LunchPro system."
    render :json => {success: true, redirect: admin_office_providers_path(@office) }
  end

private

  def allowed_params
    groupings = [:user_office, :user]

    super(groupings, params)
  end


end
