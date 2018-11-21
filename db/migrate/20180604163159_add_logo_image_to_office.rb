class AddLogoImageToOffice < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :logo_image, :string
  end
end
