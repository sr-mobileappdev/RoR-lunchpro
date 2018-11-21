module SwaggerBlocks::Auth
  extend ActiveSupport::Concern

  included do

    swagger_path "/auth/status" do
      operation :get do
        extend SwaggerBlocks::Base::AuthenticationError

        key :summary, "Check User Auth Status"
        key :description, "Validate user access token to confirm the user is still active"
        key :tags, [ "Authentication" ]

        parameter name: "user_access_token", type: :string, required: true,
                description: "Current access token for the user"

        response 200 do
          key :description, 'Returns simple status of current user account.'
          schema do
            key :'$ref', :AuthUserStatusResponse
          end
        end

      end
    end

    swagger_path "/auth/profile" do
      operation :get do
        extend SwaggerBlocks::Base::AuthenticationError

        key :summary, "User Full Profile"
        key :description, "Get profile details for the current logged in user based on user access token"
        key :tags, [ "Authentication" ]

        parameter name: "user_access_token", in: :query, type: :string, required: true,
                description: "Current access token for the user"

        response 200 do
          key :description, 'Returns simple status of current user account.'
          schema do
            key :'$ref', :ProfileResponse
          end
        end

      end
    end

    swagger_path "/auth/login" do
      operation :post do
        extend SwaggerBlocks::Base::AuthenticationError

        key :description, "Sign in a user via email and password for access to user-related functions in the API. **Note** It is not necessary to make a new `login` call after a `register` call. The register call acts as a register + login call on its own."
        key :tags, [ "Authentication" ]

        parameter name: "email", type: :string, in: :formData, required: true,
                description: "Login email address for the user attempting to login to LunchPro"

        parameter name: "password", type: :string, in: :formData, required: true,
                description: "Password for email login"

        response 200 do
          key :description, 'Returns newly created sales rep.'
          schema do
            key :'$ref', :LoginResponse
          end
        end

      end
    end

    swagger_path "/auth/password" do
      operation :post do
        extend SwaggerBlocks::Base::AuthenticationError

        key :description, "Request a password reset email be sent, based on submitted email address"
        key :tags, [ "Authentication" ]

        parameter name: "email", type: :string, in: :formData, required: true,
                description: "Login email address for the user attempting to reset password"

        response 200 do
          key :description, 'Returns message for user regarding password reset.'
          schema do
            key :'$ref', :MessageResponse
          end
        end

      end
    end

    swagger_path "/auth/register" do
      operation :post do
        extend SwaggerBlocks::Base::AuthenticationError

        key :description, "Create a new sales rep and related login"
        key :tags, [ "Authentication" ]

        parameter name: "first_name", in: :formData, type: :string, required: true,
                description: "First name of new sales rep"

        parameter name: "last_name", in: :formData, type: :string, required: true,
                description: "Last name of new sales rep"

        parameter name: "email", in: :formData, type: :string, required: true,
                description: "Login email address for the user attempting to login to LunchPro"

        parameter name: "password", in: :formData, type: :string, required: true,
                description: "Password for email login"

        parameter name: "password_confirmation", in: :formData, type: :string, required: true,
                description: "Password confirmation for email login, must match password"

        parameter name: "primary_phone", in: :formData, type: :string, required: false,
                description: "Optional primary phone number for sales rep"

        parameter name: "company_id", in: :formData, type: :string, required: false,
                description: "ID of the company assigned to this new sales rep. Alternatively a new company can be embedded and created via this call instead"

        parameter do
          key :name, 'company'
          key :type, :object
          key :description, "New company object for creation of a new company inline with registration of a sales rep"
          schema do
            key :'$ref', :CompanyNew
          end
        end

        response 200 do
          key :description, 'Returns newly created sales rep.'
          schema do
            key :'$ref', :RegisterResponse
          end
        end

      end
    end

    swagger_path "/auth/change" do
      operation :post do
        extend SwaggerBlocks::Base::AuthenticationError

        key :description, "Updates the existing logged-in seales rep, and related login"
        key :tags, [ "Authentication" ]

        parameter name: "user_access_token", in: :query, type: :string, required: true,
                description: "Current access token for the user"

        parameter name: "first_name", in: :formData, type: :string, required: false,
                description: "First name of new sales rep, soft-required (required on create only)"

        parameter name: "last_name", in: :formData, type: :string, required: false,
                description: "Last name of new sales rep, soft-required (required on create only)"

        parameter name: "email", in: :formData, type: :string, required: true,
                description: "Login email address for the user attempting to login to LunchPro"

        parameter name: "password", in: :formData, type: :string, required: true,
                description: "Password for email login"

        parameter name: "password_confirmation", in: :formData, type: :string, required: true,
                description: "Password confirmation for email login, must match password"

        parameter name: "primary_phone", in: :formData, type: :string, required: false,
                description: "Optional primary phone number for sales rep"

        parameter name: "company_id", in: :formData, type: :string, required: false,
                description: "ID of the company assigned to this new sales rep. Alternatively a new company can be embedded and created via this call instead"

        parameter do
          key :name, 'company'
          key :type, :object
          key :description, "New company object for creation of a new company inline with registration of a sales rep"
          schema do
            key :'$ref', :CompanyNew
          end
        end

        response 200 do
          key :description, 'Returns newly created sales rep.'
          schema do
            key :'$ref', :RegisterResponse
          end
        end

      end
    end

    swagger_schema :AuthUserStatusResponse do
      property :is_active do
        key :type, :boolean
        key :description, "Current access state of the user's access token"
      end
      property :status_message do
        key :type, :string
        key :description, "Generally will be null unless the user is inactive in which case this may include a user-facing message that could be presented as to why the access token no longer works."
      end
    end

    swagger_schema :ProfileResponse do
      property :sales_rep do
        key :type, :object
        key :'$ref', :SalesRep
      end
    end

    swagger_schema :RegisterResponse do
      property :user_access_token do
        key :type, :string
        key :description, "Access token which will be used on all future calls to authenticate the current logged in user"
      end
      property :sales_rep do
        key :type, :object
        key :'$ref', :SalesRep
      end
    end

    swagger_schema :LoginResponse do
      property :user_access_token do
        key :type, :string
        key :description, "Access token which will be used on all future calls to authenticate the current logged in user"
      end
      property :sales_rep do
        key :type, :object
        key :'$ref', :SalesRep
      end
    end

    swagger_schema :MessageResponse do
      property :message do
        key :type, :string
        key :description, "User-focused response message"
      end
    end

  end
end
