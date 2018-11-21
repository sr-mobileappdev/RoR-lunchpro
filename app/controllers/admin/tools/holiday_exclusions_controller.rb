class Admin::Tools::HolidayExclusionsController < AdminController
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_record
    @record = HolidayExclusion.find(params[:id])
  end

  def index
    @records = HolidayExclusion.active.all
  end

  def edit

  end

  def new
    @record = HolidayExclusion.new
  end

  def create
    @record = HolidayExclusion.new(allowed_params)

    if @record.valid? && @record.save
      flash[:notice] = "New holiday exclusion has been created"
      render :json => {success: true, redirect: admin_tools_holiday_exclusions_path(@record) }
      return
    else
      render :json => {success: false, general_error: "Unable to create record due to the following errors:", errors: @record.errors.full_messages}, status: 500
      return
    end
  end

  def update
    if @record.update(allowed_params)
      flash[:notice] = "Record has been updated. Changes will be immediately reflected across the system."
      render :json => {success: true, redirect: admin_tools_holiday_exclusions_path(@record) }
      return
    else
      render :json => {success: false, general_error: "Unable to update record due to the following errors:", errors: @record.errors.full_messages}, status: 500
      return
    end
  end

  def delete
    # These are never deleted, only deactivated
    @record.deleted!

    flash[:notice] = "The '#{@record.name}' holiday has been removed."
    render :json => {success: true, redirect: admin_tools_holiday_exclusions_path }
  end

private

  def allowed_params
    params.require(:holiday_exclusion).permit!
  end

end
