require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lunchpro
  class Application < Rails::Application

    config.exceptions_app = self.routes

    # Initialize configuration defaults for originally generated Rails version.
    config.eager_load_paths << Rails.root.join("lib/seeds")
    config.eager_load_paths << Rails.root.join("lib/sendgrid")
    config.eager_load_paths << Rails.root.join("lib/twilio")
    config.eager_load_paths << Rails.root.join("lib/misc")

    config.load_defaults 5.1

    # Disable generators we won't need for our application core
    config.generators do |g|
      g.orm             :active_record
      g.template_engine :erb
      g.test_framework  :minitest, spec: false, fixture: false
      g.stylesheets     false
      g.javascripts     false
      g.helper          false
    end

    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # Ignore UTC / timezones on time-only fields (only care about it for datetime)
    config.active_record.time_zone_aware_types = [:datetime]

    config.active_job.queue_adapter = :sidekiq

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
