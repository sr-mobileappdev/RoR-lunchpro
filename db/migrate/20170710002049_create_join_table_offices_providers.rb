class CreateJoinTableOfficesProviders < ActiveRecord::Migration[5.1]
  def change
    create_join_table :offices, :providers do |t|
      t.index [:office_id, :provider_id]
      t.index [:provider_id, :office_id]
    end
  end
end
