# app/graphql/types/profile_type.rb
Types::SalesRepType = GraphQL::ObjectType.define do
  name "SalesRep"
  field :id, !types.ID
  field :first_name, !types.String
  field :last_name, !types.String
end
