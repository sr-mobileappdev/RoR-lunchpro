class Admin::Offices::ContactsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def set_record
    @record = OfficePoc.find(params[:id])
  end

  def show

  end

  def new
    @record = OfficePoc.new()
    @record.office = @office
  end

  def create

    form = Forms::AdminOfficePoc.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add contact to office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save_and_invite
      render :json => {success: false, general_error: "Unable to add contact to office at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New office contact has been assigned to this office."
    render :json => {success: true, redirect: admin_office_providers_path(@office) }
    return

  end

  def update

    form = Forms::AdminOfficePoc.new(current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update contact due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update contact at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Office contact details have been updated."
    render :json => {success: true, redirect: admin_office_providers_path(@office) }
    return

  end
  def delete
    #check if user is trying to delete their only active office POC, and block them if they are
    if @office.office_pocs.where(:status => "active").count == 1
      flash[:alert] = "Unable to delete contact, there must be at least one active Office Contact."
      render :json => {success: true, redirect: admin_office_providers_path(@office) }
      return
    end

    #set poc to deleted
    @record.update_attributes!(status: 'deleted')
    flash[:alert] = "Office Contact has been deleted from the LunchPro system."
    render :json => {success: true, redirect: admin_office_providers_path(@office) }
  end

private

  def allowed_params
    groupings = [:office_poc]

    super(groupings, params)
  end


end
