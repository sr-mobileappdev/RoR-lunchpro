class Api::ApidocsController < ApiController

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '0.0.1'
      key :title, 'LunchPro'
      key :description, 'API for interaction and integration with Lunchpro.'
      key :termsOfService, 'http://www.lunchpro.com'
    end
    tag do
      key :name, 'Offices'
    end
    tag do
      key :name, 'Sales Reps'
    end
    tag do
      key :name, 'Restaurants'
    end
    tag do
      key :name, 'Appointments'
    end
    tag do
      key :name, 'Orders'
    end
    tag do
      key :name, 'Authentication'
    end
    key :host, (Rails.env.development?) ? 'localhost:3000' : 'lunch.lplastmile.com'
    key :basePath, '/api/v1'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    Api::V1::MetaController,
    Api::V1::OfficesController,
    Api::V1::RestaurantsController,
    Api::V1::SalesRepsController,
    Api::V1::AppointmentsController,
    Api::V1::OrdersController,
    Api::V1::AuthController,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
