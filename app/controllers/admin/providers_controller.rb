class Admin::ProvidersController < AdminTableController
  before_action :set_record, only: [:show, :edit, :update]

  def set_record
    @record = Provider.find(params[:id])
  end

  # -- Scope Table
  def scope_table
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = Provider.none

    if params[:scope]

    else
      @manager = Managers::AdminTableManager.new(Provider, ['id','name','display_location_single'])
      @records = @manager.paged(@page, @per_page)
    end

  end

  def get_table_path(params)
    admin_providers_path(params)
  end
  # --


  def index

  end

  def show
    if params[:office_id].present?
      # Reroute this request to the office namespace path
      redirect_to admin_office_provider_path(params[:office_id], params[:id])
    end

  end

end
