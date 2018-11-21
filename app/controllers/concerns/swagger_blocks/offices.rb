module SwaggerBlocks::Offices
  extend ActiveSupport::Concern

  included do

    swagger_path "/offices" do

      operation :get do

        key :description, "List offices based on search criteria"
        key :tags, [ "Offices" ]

        parameter name: "sales_rep_id", type: :integer, in: :query, required: false,
                description: "Optional sales_rep_id, to return only offices associated with a given sales rep"

        parameter do
          key :name, "include_params"
          key :in, :query
          key :description, "Optional array of desired fields to return on each office in the result set."
          key :type, :array
        end

        response 200 do
          key :description, 'Returns offices with default params or a limited set of params based on include_params array.'
          schema do
            key :'$ref', :OfficesResponse
          end
        end

      end

      operation :post do

        key :description, "Create a new office"
        key :tags, [ "Offices" ]

      end

    end

    swagger_path "/offices/{id}" do

      operation :put do

        key :description, "Update an office's details"
        key :tags, [ "Offices" ]

      end

    end


    swagger_schema :OfficesResponse do
      property :offices do
        key :type, :array
        items do
          key :'$ref', :Office
        end
      end
    end


    swagger_schema :Office do
      allOf do
        schema do
          property :id do
            key :type, :string
          end
          property :status do
            key :type, :string
          end
          property :name do
            key :type, :string
          end
          property :address_line1 do
            key :type, :string
          end
          property :address_line2 do
            key :type, :string
          end
          property :address_line3 do
            key :type, :string
          end
          property :city do
            key :type, :string
          end
          property :state do
            key :type, :string
          end
          property :postal_code do
            key :type, :string
          end
          property :country do
            key :type, :string
          end
          property :total_staff do
            key :type, :integer
          end
          property :office_policy do
            key :type, :string
          end
          property :food_preferences do
            key :type, :string
          end
          property :delivery_instructions do
            key :type, :string
          end
          property :lat do
            key :type, :number
          end
          property :lon do
            key :type, :number
          end
          property :policies_last_updated do
            key :type, :string
            key :format, :date
          end
        end
      end
    end

  end
end
