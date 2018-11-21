class Api::V1::MetaController < ApiController
  include SwaggerBlocks::Base
  include SwaggerBlocks::Meta
  skip_before_action :authenticate_user, only: [:index, :company]

  # GET :: Returns metadata on API user and lookup data such as companies
  def index

    @scoped_params = define_scoped_params(params[:include_params])

    companies = Company.all.order(name: :asc)

    meta_data = {api_status: 'active', api_usage_warning: nil, companies: ActiveModelSerializers::SerializableResource.new(companies, each_serializer: CompaniesSerializer)}

    render json: meta_data and return

  end

  # POST :: Creates a new company record, standalone
  def company
    unless required_params_are_present?([:name])
      v1_unaccepted_response("AUTH-001-Missing", "Missing required company name paramter") and return
    end

    company_name = params[:name]

    company = Company.new(name: company_name, status: 'active', created_by_id: nil)
    existing = Company.where(Company.arel_table[:name].matches(company_name)).first

    response = {}
    if existing
      company = existing
      response[:warning] = {type: 'existing', message: 'The company you are trying to create already exists.'}
    end

    if existing || company.save
      response[:company] = CompaniesSerializer.new(company)
      render json: response and return
    else
      v1_unaccepted_response("AUTH-004-Failure", "Unable to create new company due to the following errors", company.errors.full_messages) and return
    end

  end


end
