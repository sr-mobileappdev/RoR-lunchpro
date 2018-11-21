
Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV['REDIS_URL']}/12" }
end
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV['REDIS_URL']}/12" }
end

rails_root = File.dirname(__FILE__) + '/../..'
schedule_file = rails_root + "/config/cron.yml"
if File.exists?(schedule_file)
  sidekiq_cron = YAML.load_file(schedule_file)
  Sidekiq::Cron::Job.destroy_all!
  Sidekiq::Cron::Job.load_from_hash! sidekiq_cron[Rails.env]
end
