class Admin::Offices::PoliciesController < AdminController
  before_action :set_parent_record

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def index

  end

end
