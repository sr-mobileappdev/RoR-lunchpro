class Api::V1::OfficesController < ApiController
  include SwaggerBlocks::Offices

  before_action :set_record, only: [:show, :update]
  skip_before_action :check_user_space, only: [:show]

  def set_record
    @office = Office.active.find(params[:id])
  end
  
  def index

    @scoped_params = define_scoped_params(params[:include_params])
    @sales_rep = nil

    records = []

    if params[:sales_rep_id].present?
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      records = @sales_rep.active_offices
    else
      records = Office.active.where(:internal => true).where.not(:activated_at => nil)
    end

    if params[:office_name].present?
      records = records.where("name like ?", "%#{params[:office_name]}%")
    end

    response_summary = {count: records.count} #response_summary = {count: records.count, total_count: records.total_count, page: @page, total_pages: records.total_pages}
    if @sales_rep
      response_summary = response_summary.merge({limited_by_sales_rep: true})
    end

    render json: {meta: response_summary, offices: ActiveModelSerializers::SerializableResource.new(records, each_serializer: OfficesSerializer, scope: @scoped_params)} and return

  end

  def show
    @sales_rep = nil

    time_range = Time.zone.now.to_date.beginning_of_week..Time.zone.now.to_date.end_of_week
    if params[:start_date].present? && params[:end_date].present?
      begin
        time_range = Date.parse(params[:start_date])..Date.parse(params[:end_date])
      rescue Exception => ex
      end
    end

    if params[:sales_rep_id].present? && @office
      response_summary = {limited_by_sales_rep: true}
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      if !@sales_rep.present?
        v1_unaccepted_response("OFF-001-MissinRep", "You must provide a valid sales rep id") and return
      end
    end
    if params[:last_poll].present?
    	last_poll_time = Time.parse(params[:last_poll])
    	office_changed = last_poll_time <= @office.updated_at || @office.office_exclude_dates.any?{ |x| last_poll_time <= x.updated_at } || @office.diet_restrictions.any?{ |x| last_poll_time <= x.updated_at }
    	office_to_return = nil
    	if office_changed
	    	office_to_return = @office.slice(:id, :name, :address_line1, :address_line2, :address_line3, :creating_sales_rep_id, :city, :state, :postal_code, :country, :office_policy, :food_preferences, :delivery_instructions, :policies_last_updated_at, :phone, :timezone, :internal, :appointments_until)
	    	office_to_return = office_to_return.merge({ :lat => (@office.latitude.present? ? @office.latitude.to_s : nil), :lon => (@office.longitude.present? ? @office.longitude.to_s : nil), :total_staff => (@office.total_staff_count || 0), :office_exclude_dates => @office.office_exclude_dates.map{ |x| x.slice(:id).merge({:starts_at_date => x.starts_at_date, :ends_at_date => x.ends_at_date }) }, :diet_restrictions => @office.diet_restrictions_offices.map{ |y| y.slice(:staff_count).merge({:id => y.diet_restriction.id, :name => y.diet_restriction.name, :description => y.diet_restriction.description}) }  })
    	end
    	
    	all_offices_providers = @office.providers.select{ |x| last_poll_time <= x.updated_at || x.provider_availabilities.any?{ |y| last_poll_time <= y.updated_at } }
    	providers_to_return = all_offices_providers.map{ |x| x.slice(:id, :first_name, :last_name, :status, :title).merge({:provider_availabilities => x.provider_availabilities.active.map{ |y| y.slice(:id, :day_of_week, :starts_at, :ends_at)}}) }
    	
		to_return = {}
		to_return[:office] = office_to_return
		to_return[:providers] = providers_to_return
		
		render json: to_return and return
    else
	    render json: @office, serializer: OfficesSerializer, scope: {'sales_rep': @sales_rep, 'single_office': true, 'offices_sales_reps': @sales_rep.present?, 'time_range': time_range}
    end
  end
  
  def create  	
  # instantiate records
	if(!params[:creating_sales_rep_id].present? || !SalesRep.exists?(params[:creating_sales_rep_id]))
		render :json => {success: false, general_error: "Invalid sales rep ID"}, status: 400
      	return
	end
	current_sales_rep = SalesRep.find(params[:creating_sales_rep_id])
	
  	newOffice = Office.new(:name => params[:name], :internal => false, :total_staff_count => params[:total_staff], :activated_at => Time.now.utc, :activated_by_id => current_sales_rep.user_id, :creating_sales_rep_id => params[:creating_sales_rep_id], :address_line1 => params[:address_line1], :address_line2 => params[:address_line2], :postal_code => params[:postal_code], :city => params[:city], :state => params[:state], :phone => params[:phone], :timezone => params[:timezone])
  	newOfficeSalesRep = OfficesSalesRep.new(:sales_rep_id => newOffice.creating_sales_rep_id, :status => 1, :office => newOffice)
  	  	
  #validate records
  	form = Forms::Api::FormOffice.new(newOffice, newOfficeSalesRep)
  	
  	unless form.valid?
  		render :json => {success: false, message: "Unable to create new office due to the following errors or notices:", errors: form.errors}, status: 400
      	return
  	end
  #save records
  	unless form.save
      render :json => {success: false, message: "Unable to create new office at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
  #return new records
	render json: { success: true, message: "Successfully created a new office with corresponding point of contact and sales rep.", office: newOffice, office_sales_rep: newOfficeSalesRep } and return
  end

  def update
  #instantiate records
  	@office.assign_attributes(update_params);    
  #validate records
  	form = Forms::Api::FormOffice.new(@office)
  	
  	unless form.valid?
  		render :json => {success: false, message: "Unable to update the office due to the following errors or notices:", errors: form.errors}, status: 400
      	return
  	end
  #save records
  	unless form.save
      render :json => {success: false, message: "Unable to update the office at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    
    #return updated record
	render json: { success: true, message: "Successfully updated the office.", office: @office } and return
  end
  
  private
  def update_params
  	params.require(:office).permit(:name, :address_line1, :address_line2, :postal_code, :city, :state, :phone, :timezone)
  end
  
end
