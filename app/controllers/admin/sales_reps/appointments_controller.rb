class Admin::SalesReps::AppointmentsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  def set_record
    @record = Appointment.find(params[:id])
  end

  def show

  end

  def new

  end

  def create

  end

private

  def appointment_params
    params.require(:appointment).permit!
  end


end
