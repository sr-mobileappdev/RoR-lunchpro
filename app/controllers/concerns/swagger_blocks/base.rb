module SwaggerBlocks::Base
  extend ActiveSupport::Concern

  module AuthenticationError
    def self.extended(base)
      base.response 401 do
        key :description, 'Not Authorized'
        schema do
          key :'$ref', :AuthenticationError
        end
      end
      base.response 404 do
        key :description, 'Not Found'
        schema do
          key :'$ref', :NotFoundError
        end
      end
      base.response 406 do
        key :description, 'Unaccepted'
        schema do
          key :'$ref', :UnacceptedError
        end
      end
    end
  end

  included do

    swagger_schema :AuthenticationError do
      allOf do
        schema do
          property :message do
            key :type, :string
          end
        end
      end
    end

    swagger_schema :NotFoundError do
      allOf do
        schema do
          property :message do
            key :type, :string
          end
        end
      end
    end

    swagger_schema :UnacceptedError do
      allOf do
        schema do
          property :error_code do
            key :type, :string
          end
          property :message do
            key :type, :string
          end
          property :errors do
            key :type, :array
            key :items, :string
          end
        end
      end
    end

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

    swagger_schema :Company do
      allOf do
        schema do
          property :id do
            key :type, :string
          end
          property :name do
            key :type, :string
          end
        end
      end
    end

    swagger_schema :Drug do
      allOf do
        schema do
          property :id do
            key :type, :string
          end
          property :brand do
            key :type, :string
          end
          property :generic_name do
            key :type, :string
          end
        end
      end
    end

    swagger_schema :CompanyNew do
      allOf do
        schema do
          property :name do
            key :type, :string
          end
        end
      end
    end

    swagger_schema :ApiUser do
      allOf do
        schema do
          property :id do
            key :type, :string
          end
          property :user_name do
            key :type, :string
          end
          property :environment do
            key :type, :string
          end
        end
      end
    end

  end

end
