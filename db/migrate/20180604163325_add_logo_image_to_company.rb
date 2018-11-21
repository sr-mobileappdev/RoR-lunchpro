class AddLogoImageToCompany < ActiveRecord::Migration[5.1]
  def change
    add_column :companies, :logo_image, :string
  end
end
