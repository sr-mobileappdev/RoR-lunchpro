Types::QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  field :sales_rep do
    type Types::SalesRepType
    argument :id, !types.ID
    description "Find a Sales Rep by ID"
    resolve ->(obj, args, ctx) { SalesRep.find(args["id"]) }
  end

end
