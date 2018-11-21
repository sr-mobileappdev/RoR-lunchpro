class OrderTransaction < ApplicationRecord

	belongs_to :payment_method
	belongs_to :order

	validates_presence_of :payment_method, :order, :status, :transaction_type

	enum status: { success: Constants::STATUS_COMPLETED, failure: Constants::STATUS_REJECTED }
	enum transaction_type: { authorized: 1, captured: 2, refunded: 3 }



	def able_to_capture?
		# is the authorization within the 7 day (minus 5 min) window to be valid
		# An authorization transaction can only have one sucessful capture
    begin 
		  (order.active? || order.completed?) && order.authorized? && !order.captured? && Time.now.utc <= (order.pre_auth_transaction.created_at.utc + 10_075.minutes)
    rescue Exception => ex
      Rollbar.error(ex)
      false
    end
	end#able_to_capture?


	def able_to_refund?
    begin
  		(order.captured? && order.refunded_amount_cents <= order.captured_amount_cents) ||
      (order.authorized? && order.refunded_amount_cents <= order.authorized_amount_cents)
    rescue Exception => ex
      Rollbar.error(ex)
      false
    end
	end#able_to_refund?



end # OrderTransaction
