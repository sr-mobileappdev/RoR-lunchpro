class Admin::PaymentController < AdminController
  before_action :set_record, only: [:show, :edit, :update]

  def set_record
    @record = Payment.find(params[:id])
  end

  def show

    if params[:sales_rep_id].present?
      # Reroute this request to the office namespace path
      redirect_to admin_rep_payment_path(params[:sales_rep_id], params[:id])
    end

  end

end
