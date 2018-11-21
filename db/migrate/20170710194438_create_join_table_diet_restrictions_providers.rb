class CreateJoinTableDietRestrictionsProviders < ActiveRecord::Migration[5.1]
  def change
    create_join_table :diet_restrictions, :providers do |t|
      t.index [:diet_restriction_id, :provider_id], name: :diet_restrictions_providers_diet_id_and_prov_id
      t.index [:provider_id, :diet_restriction_id], name: :diet_restrictions_providers_prov_id_and_diet_id
    end
  end
end
