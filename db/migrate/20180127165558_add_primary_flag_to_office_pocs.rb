class AddPrimaryFlagToOfficePocs < ActiveRecord::Migration[5.1]
  def change
    add_column :office_pocs, :primary, :bool
  end
end
