module SwaggerBlocks::Orders
  extend ActiveSupport::Concern

  included do

    swagger_path "/orders" do

      operation :get do

        key :description, "List orders based on search criteria"
        key :tags, [ "Orders" ]

      end

    end

    swagger_path "/orders" do

      operation :post do

        key :description, "Create a new order"
        key :tags, [ "Orders" ]

      end

    end

    swagger_path "/orders/{id}" do

      operation :put do

        key :description, "Update an order"
        key :tags, [ "Orders" ]

      end

    end

  end
end
