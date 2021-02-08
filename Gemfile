source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.1'
gem 'pg', '~> 0.21'
#gem 'puma', '~> 3.7'
# Use SCSS for stylesheets (optional)
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.0'

# -- Gems Added

#Email ICS Attachments
gem 'icalendar'

#PDF Generation

gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
#phone number masking
gem 'jquery_mask_rails', '~> 0.1.0'


# GraphQL / API
gem 'graphql'

# Use jquery as the JavaScript library
gem 'jquery-rails'

gem 'bootstrap', git: 'https://github.com/twbs/bootstrap-rubygem'
gem 'execjs'
gem 'mini_racer'
gem 'devise'
gem "devise_invitable", "~> 1.7.0"

gem 'figaro' # application.yml / better ENV vars

gem 'stripe'

gem 'kaminari' # Pagination

gem 'tod' # Time of Day Management

gem 'capistrano-slackify', require: false # Slack notify

gem 'sendgrid-ruby' # Email Delivery
gem 'sparkpost_rails', "~> 1.4.0", git: 'https://github.com/jlehman/sparkpost_rails' # Sendgrid _might_ drop the ball... just in case.

gem 'sidekiq' # Jobs
gem 'sidekiq-cron'
gem 'sinatra', require: false #used for sidekiq web interface

gem "twilio-ruby", "~> 5.1.0" # Telephony SMS

gem "carrierwave", "~> 1.3.2" # Uploads
gem 'fog', require: 'fog/aws' # Uploads, too

gem "geocoder"

gem 'flavour_saver' # Handlebar Style Template Handling, for emails and notifications
gem 'tilt' # Handlebar Style Template Handling, for emails and notifications

gem 'ace-rails-ap' # ACE code editor, for HTML email editing

gem "slack-notifier" # Speak to slack, all the things
gem "rollbar" # Error reporting
gem "tracker_api" # Route stuff to PT, maybe... maybe not

gem 'knock'

gem 'chronic' # easily parses dates, occurrences, and timeframes

# * * * CSV Imports
gem 'csv-importer'

# * * * JSON Serializing
gem 'active_model_serializers'

# * * * Swagger / API Stuff
gem 'swagger-blocks'
gem 'grape-swagger-rails' # We don't use grape, but this tool works with swagger JSON files and doesn't care about Grape from all I can tell
# Use ChartJS for analytic graphs & charts
gem 'chart-js-rails'

# --


group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '~> 2.13'
  gem "minitest-rails-capybara", "~> 3.0.0"
  gem "minitest-rails", "~> 3.0.0"
  gem "factory_girl_rails", "~> 4.6.0"
  gem 'selenium-webdriver'
  gem 'minitest-reporters'
  gem "guard", "~> 2.14", :require => false
  gem 'guard-livereload', '~> 2.5', :require => false
  gem "guard-minitest", "~> 2.4", :require => false
	gem 'puma' # use puma as the web server
	gem 'faker' # For fake data generation where needed
end

group :development do
  gem 'capistrano-rails'
  gem 'web-console', '>= 3.3.0' # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring' # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring-watcher-listen', '~> 2.0.0'
	gem 'pry-rails' # Better IRB
	gem "better_errors"
  gem 'binding_of_caller'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'graphiql-rails', group: :development
