class CreateImports < ActiveRecord::Migration[5.1]
  def change
    create_table :imports do |t|
      t.string :import_file
      t.integer :uploaded_by_id
      t.string :import_model
      t.integer :status, default: 1

      t.timestamps
    end
  end
end
