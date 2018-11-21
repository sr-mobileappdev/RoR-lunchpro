module SwaggerBlocks::SalesReps
  extend ActiveSupport::Concern

  included do

    swagger_path "/sales_reps" do

      operation :get do

        key :description, "List sales reps based on search criteria"
        key :tags, [ "Sales Reps" ]

      end


    end

    swagger_path "/sales_reps/{id}" do

      operation :get do

        key :description, "Get details for a specific sales rep"
        key :tags, [ "Sales Reps" ]

      end


    end

    swagger_path "/sales_reps/{id}" do

      operation :put do

        key :description, "Update a sales rep's details"
        key :tags, [ "Sales Reps" ]

      end

    end

    swagger_path "/sales_reps/{id}/invite_partner/{parter_id}" do

      operation :put do

        key :description, "Initiate a sales rep partner request to another sales rep"
        key :tags, [ "Sales Reps" ]

      end

    end

    swagger_path "/sales_reps/{id}/accept_partner/{request_id}" do

      operation :put do

        key :description, "Accepts a sales rep partner request from another sales reps"
        key :tags, [ "Sales Reps" ]

      end

    end


    swagger_schema :SalesRep do
      allOf do
        schema do
          property :id do
            key :type, :string
          end
          property :first_name do
            key :type, :string
          end
          property :last_name do
            key :type, :string
          end
          property :company_id do
            key :type, :integer
          end
          property :login_email do
            key :type, :string
          end
          property :user_phone do
            key :type, :string
          end
          property :is_activated do
            key :type, :boolean
          end
          property :drugs do
            key :type, :array
            items do
              key :'$ref', :Drug
            end
          end
          property :profile_image_url do
            key :type, :string
          end
        end
      end
    end


  end
end
