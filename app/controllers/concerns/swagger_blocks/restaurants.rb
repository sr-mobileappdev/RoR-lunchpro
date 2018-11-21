module SwaggerBlocks::Restaurants
  extend ActiveSupport::Concern

  included do

    swagger_path "/restaurants" do

      operation :get do

        key :description, "List restaurants based on search criteria"
        key :tags, [ "Restaurants" ]

      end

      operation :post do

        key :description, "Create a new restaurant"
        key :tags, [ "Restaurants" ]

      end

    end

    swagger_path "/restaurants/{id}" do

      operation :put do

        key :description, "Update a restaurant's details"
        key :tags, [ "Restaurants" ]

      end

    end

  end
end
