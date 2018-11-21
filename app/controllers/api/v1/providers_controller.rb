class Api::V1::ProvidersController < ApiController

skip_before_action :check_user_space, only: [:index]

  def index
    @scoped_params = define_scoped_params(params[:include_params])
    @sales_rep = nil
  	if(params[:sales_rep_id].present?)
  		@sales_rep = SalesRep.find(params[:sales_rep_id])
  	end

    
    records = []
    
    if @sales_rep.present?
    	records = Provider.for_office_ids(@sales_rep.offices_sales_reps.active.pluck(:office_id))
    elsif params[:office_id].present?
    	office_ids = []
    	office_ids << params[:office_id]
    	records = Provider.for_office_ids(office_ids)
    else
  		records = Provider.active      
    end
    
    response_summary = {limited_by_sales_rep: @sales_rep.present?, count: records.count}

    render json: {meta: response_summary, providers: ActiveModelSerializers::SerializableResource.new(records, each_serializer: ProvidersSerializer, scope: @scoped_params)} and return

  end

end
