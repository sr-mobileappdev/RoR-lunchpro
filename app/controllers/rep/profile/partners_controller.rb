class Rep::Profile::PartnersController < ApplicationRepsController
  before_action :set_rep

  before_action :set_record, only: [:delete]
  before_action :set_pending_record, only: [:reject, :accept, :partner_request]

  def set_rep
    @sales_rep = current_user.sales_rep
  end

  def set_record
    @record = SalesRepPartner.where(:sales_rep_id => @sales_rep.id, :partner_id => params[:id], status: ["pending", "accepted"]).first
  end

  def set_pending_record
    @record = SalesRepPartner.where(:sales_rep_id => params[:id], :partner_id => @sales_rep.id, status: ["pending", "accepted"]).first
  end

  def create
    partner_request = SalesRepPartner.new(partner_params)
    partner_request.assign_attributes(:status => 'pending', :sales_rep_id => @sales_rep.id)
    unless partner_request.valid?
      render :json => {success: false, general_error: "Unable to send partner request due to the following errors or notices:", 
        errors: partner_request.errors.full_messages}, status: 500
      return
    end
    if partner_request.partner
      partner_request.save
    end
    flash[:success] = "Partner Request has been sent!"
    redirect_to rep_profile_index_path(tab: 'partner')
  end

  def accept
    @record.assign_attributes(:status => 'accepted')
    if @record.valid? && @record.save

    else
      flash[:error] = @record.errors.full_messages.first
      redirect_to rep_profile_index_path(tab: 'partner') and return
    end
    @partner_record = SalesRepPartner.where(:status => 'rejected', :sales_rep_id => @sales_rep.id, :partner_id => @record.sales_rep_id).first

    if @partner_record
      @partner_record.update_attributes(:status => 'accepted')
      rep_to_notify = @partner_record
      record = @partner_record
    else
      @new_partner_record = SalesRepPartner.new(:status => 'accepted', :sales_rep_id => @sales_rep.id, :partner_id => @record.sales_rep_id)
      if @new_partner_record.valid? && @new_partner_record.save        
        rep_to_notify = @new_partner_record.partner
        record = @new_partner_record
      else
        flash[:error] = @new_partner_record.errors.full_messages.first
        redirect_to rep_profile_index_path(tab: 'partner') and return
      end
    end
    
    Managers::NotificationManager.trigger_notifications([214], [rep_to_notify, record])
    flash[:success] = "Partner Request has been accepted!"
    redirect_to rep_profile_index_path(tab: 'partner')
  end


  def delete
    @record.update_attributes(:status => 'deleted')
    @partner_record = SalesRepPartner.where(:status => 'accepted', :sales_rep_id => @record.partner_id, :partner_id => @sales_rep.id).first
    if @partner_record
      @partner_record.update_attributes(:status => 'deleted')
    end
    flash[:success] = "Partner has been removed!"
    redirect_to rep_profile_index_path(tab: 'partner')
  end

  def reject
    existing_record = @sales_rep.sales_rep_partners.where(:status => "rejected", :partner_id => @record.sales_rep_id).first
    if existing_record.present?
      existing_record.update_attributes(:status => 'deleted')
      @record.update_attributes(:status => 'deleted')
    else
      @record.update_attributes(:status => 'rejected')
    end
    flash[:success] = "Partner request has been rejected!"
    redirect_to rep_profile_index_path(tab: 'partner')
  end

  def partner_request
    if @xhr
      if modal?
        @record = SalesRepPartner.where(:sales_rep_id => params[:partner_id], :partner_id => @sales_rep.id, status: ["pending", "accepted"]).first
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/rep_partner_request', :layout => false, :formats => [:html])}
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    else
      redirect_to current_rep_calendars_path
    end
  end

  private

  def partner_params
    params.require(:sales_rep_partner).permit(:partner_email, :sales_rep_id, :status)
  end
end
