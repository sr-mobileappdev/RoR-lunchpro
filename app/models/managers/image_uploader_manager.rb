# encoding: utf-8

class Managers::ImageUploaderManager < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  def store_dir
   # "#{Rails.env}/images/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"

    #if restaurant logo
    if (mounted_as == :brand_image && model.class.to_s == 'Restaurant') || (mounted_as == :profile_image && model.class.to_s == "SalesRep")
      "#{model.class.to_s}/#{model.id}/images/#{mounted_as}"
    #if menu item image
    elsif model.class.to_s == 'MenuItemImage'
      "Restaurant/#{model.menu_item.restaurant.id}/images/menu_item/#{model.menu_item_id}"
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # def content_type_whitelist
  #   /image\/|ms-excel|ms-word|pdf/
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
