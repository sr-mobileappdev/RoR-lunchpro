CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',                             # required
    :aws_access_key_id      => ENV['S3_AWS_ACCESS'],              # required
    :aws_secret_access_key  => ENV['S3_AWS_SECRET'],              # required
    :region                 => 'us-east-1'                        # optional, defaults to 'us-east-1'
  }

  config.fog_directory  = ENV['S3_AWS_BUCKET']                               # required
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}

  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  elsif Rails.env.development?
=begin    config.permissions = 0666
    config.directory_permissions = 0777
    config.storage = :file
=end
    config.storage = :fog
  else
    config.storage = :fog
  end


end
