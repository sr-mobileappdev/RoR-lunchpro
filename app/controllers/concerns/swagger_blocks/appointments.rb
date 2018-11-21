module SwaggerBlocks::Appointments
  extend ActiveSupport::Concern

  included do

    swagger_path "/appointments" do

      operation :get do

        key :description, "List appointments slots based on office or sales rep, along with a timeframe. If no timeframe is provided the response will
                            include only the current week of appointment slots related to the sales rep or office. If no sales rep ID or office ID is provided
                            the API will return appointments based on the sales rep associated with the user_access_token. Passing an office ID will take precidence
                            over the current logged in sales rep, and will return all slots for the given office regardless of current sales rep user."

        key :tags, [ "Appointments" ]

        parameter name: "user_access_token", type: :string, in: :query, required: true,
                description: "Current access token for the user"

        parameter name: "start_date", type: :string, format: :date, in: :query, required: false,
                description: "Optional start_date from which to return appointment slots. If no start and end dates are given, the current week will be returned."

        parameter name: "end_date", type: :string, format: :date, in: :query, required: false,
                description: "Optional end_date until which to return appointment slots. If no start and end dates are given, the current week will be returned."

        parameter name: "office_id", type: :integer, in: :query, required: false,
                description: "Optional office_id, to return all appointments for a given office"

        parameter name: "sales_rep_id", type: :integer, in: :query, required: false,
                description: "Optional sales_rep_id, to return all appointments for a given sales rep"

      end

    end

    swagger_path "/appointments" do

      operation :post do

        key :description, "Create a new appointment"
        key :tags, [ "Appointments" ]

      end

    end

    swagger_path "/appointments/{id}" do

      operation :put do

        key :description, "Update an appointment"
        key :tags, [ "Appointments" ]

      end

    end

    swagger_path "/appointments/{id}" do

      operation :put do

        key :description, "Update an appointment"
        key :tags, [ "Appointments" ]

      end

    end

  end
end
