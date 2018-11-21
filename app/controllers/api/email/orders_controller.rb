class Api::Email::OrdersController < ApplicationController

	def confirm
		#redirect if uid is not present in url
		unless params[:uid].present?
		  redirect_to "/" and return
		end
		#set decryptor
        crypt = ActiveSupport::MessageEncryptor.new(ENV['PASSCODE_KEY'])
        begin
        	#get encrypted order id 
        	encrypted_id = crypt.decrypt_and_verify(params[:uid])
      	rescue Exception => ex
			redirect_to "/" and return
		end
		#if order does not exist with decrypted order id, redirect
        order = Order.where(id: encrypted_id).first
        if !order.present? || (order.present? && !order.appointment)
        	redirect_to "/" and return
        end

        #confirm or alert user thatorder has been alraedy confirmed
        if order.restaurant_confirmed
        	flash[:alert] = "Order has already been confirmed!"
        else
        	order.appointment.confirm_for_restaurant!
        	flash[:success] = "Order has been confirmed!"
        end

        
        redirect_to "/" and return
	end
end