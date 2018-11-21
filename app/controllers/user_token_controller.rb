class UserTokenController < Knock::AuthTokenController

	def create
		user_id = auth_token.payload[:sub]
		user = User.find(user_id)	
		sales_rep = user.sales_rep
		sales_rep_for_response = nil
		office_id = nil
		if user.user_office.present?
			office_id = user.user_office.office_id
		end
		if sales_rep.present?
			profile_image_url = nil
			if sales_rep.profile_image.present?
				profile_image_url = sales_rep.profile_image.url
			end
			drug_sales_reps = []
  			sales_rep.drugs_sales_reps.active.each do |d|
  				drug_sales_reps << d.as_json(:include => "drug")
  			end
			sales_rep_for_response = sales_rep.as_json().merge({ sales_rep_phones: sales_rep.sales_rep_phones.active, sales_rep_emails: sales_rep.sales_rep_emails.active, company: sales_rep.company, drugs_sales_reps: drug_sales_reps })
		end	
		render json: { user_access_token: auth_token.token, expiration_utc_seconds: auth_token.payload[:exp], sales_rep: sales_rep_for_response, office_id: office_id }, status: 201 and return
	end
end
