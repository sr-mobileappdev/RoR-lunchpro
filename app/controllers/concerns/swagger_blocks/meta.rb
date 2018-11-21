module SwaggerBlocks::Meta
  extend ActiveSupport::Concern

  included do
    swagger_path "/meta" do
      operation :get do
        extend SwaggerBlocks::Base::AuthenticationError

        key :description, "Get all lookups and metadata used within the system. "
        key :tags, [ "Meta" ]

        # parameter do
        #   key :name, "include_params"
        #   key :in, :query
        #   key :type, :array
        # end

        response 200 do
          key :description, 'Returns metadata used within the system.'
          schema do
            key :'$ref', :MetaResponse
          end
        end

      end
    end

    swagger_path "/meta/company" do
      operation :post do
        extend SwaggerBlocks::Base::AuthenticationError

        key :description, "Create a new company record. "
        key :tags, [ "Meta" ]

        parameter do
          key :name, "name"
          key :in, :formData
          key :type, :string
          key :required, true
        end

        response 200 do
          key :description, 'Returns newly-created company record.'
          schema do
            key :'$ref', :Company
          end
        end

      end
    end

    swagger_schema :MetaResponse do
      property :api_user do
        key :type, :object
        key :'$ref', :ApiUser
      end
      property :api_status do
        key :type, :string
        key :description, "Current API accessibility status. Returned values include: [`active`,`maintenance`]. When in maintenance mode the API may return maintenance failures on some calls"
      end
      property :api_usage_warning do
        key :type, :string
        key :description, "Returns a null value unless the API user is in a usage warning state in which case a warning message is returned. Usage warnings could result from rate limiter or flagged abuse of the API"
      end
      property :companies do
        key :type, :array
        items do
          key :'$ref', :Company
        end
      end
    end

    # swagger_schema :NotFoundError do
    #   allOf do
    #     schema do
    #       property :message do
    #         key :type, :string
    #       end
    #     end
    #   end
    # end

    # swagger_schema :UnacceptedError do
    #   allOf do
    #     schema do
    #       property :error_code do
    #         key :type, :string
    #       end
    #       property :message do
    #         key :type, :string
    #       end
    #       property :errors do
    #         key :type, :array
    #         key :items, :string
    #       end
    #     end
    #   end
    # end

    # swagger_schema :IncludeParams do
    #   allOf do
    #     schema do
    #       property :include_params do
    #         key :type, :array
    #         key :items, :string
    #       end
    #     end
    #   end
    # end

  end
end
