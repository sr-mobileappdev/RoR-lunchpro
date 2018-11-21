class DropLunchpadTable < ActiveRecord::Migration[5.1]
  def up
    drop_table :lunchpads
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
