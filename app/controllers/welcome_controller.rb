class WelcomeController < ApplicationController

  def new
    space = "space_sales_rep"
    if params[:space].present?
      case params[:space]
        when "sales_rep"
          space = "space_sales_rep"
        when "office"
          space = "space_office"
        when "restaurant"
          space = "space_restaurant"
      end
    end

    @user = User.new(space: space)
  end

  def create
    errors = []
    sales_rep = nil

    # Build the user first
    user = User.new(allowed_params)
    if user.password != allowed_params[:password_confirmation]
      errors << "Your password and password confirmation do not match"
    end

    ActiveRecord::Base.transaction do
      if errors.count == 0 && user.save

        if user.space_sales_rep?
          sales_rep ||= SalesRep.new(user_id: user.id)
          sales_rep.assign_attributes(sales_rep_attributes.merge({first_name: user.first_name, last_name: user.last_name}))

          if params[:company_id].present?
            company = Company.find(params[:company_id])
            sales_rep.company_id = company.id
          end

          unless sales_rep.valid? && sales_rep.save
            errors += sales_rep.errors.full_messages
            raise ActiveRecord::Rollback
          end

        elsif user.space_restaurant?

        elsif user.space_office?

        else
          # Not allowed
        end
      else
        raise ActiveRecord::Rollback
      end
    end

    if errors.count == 0
      # Done, now send them somewhere else
      sign_in(:user, user, { :bypass => true })
      redirect_to current_rep_calendars_path if sales_rep
    else

    end

  end

private

  def allowed_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :space)
  end

  def sales_rep_attributes
    params.permit(:company_id)
  end

end
