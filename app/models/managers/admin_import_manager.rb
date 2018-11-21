class Managers::AdminImportManager
  attr_reader :current_user

  def initialize(user)
    @current_user = user
  end

  def import_with_file(model, csv_file)
    case model
      when MenuItem
        menu_item_import(csv_file)
      else
        return false
    end
  end

private

  def menu_item_import(csv_file)

    Imports::ImportMenuItems.new(file: csv_file) do
      # Skip existing records
      after_build do |menu_item|
        menu_item.modified_by_user_id = @current_user.id if @current_user
      end
    end

  end

end
