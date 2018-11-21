# config valid only for current version of Capistrano
lock "3.9.0"

set :application, "lunchpro"
set :repo_url, "git@github.com:Lunch2018/LP2017.git"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref develop`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/srv/lunchpro"

# Default value for :format is :airbrussh.
# set :format, :airbrussh
# You can configure the Airbrussh format using :format_options.
# These are the defaults.
set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/application.yml"

# Default value for linked_dirs is []
#append :linked_dirs, "/var/log/ruby/pids", "/var/log/ruby/cache", "/var/log/ruby/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
set :local_user, "deploy"

# Default value for keep_releases is 5
set :keep_releases, 2


# Slack stuff

set :slack_username, 'Deployment Bot'
set :slack_emoji, ':flag-at:'
set :slack_fields, ['stage', 'branch']
set :slack_channel, '#devops'

set :slack_deploy_starting_text, -> {
  "#{fetch(:stage)} deploy starting with revision/branch #{fetch(:current_revision, fetch(:branch))} for #{fetch(:application)}"
}
set :slack_deploy_failed_text, -> {
  "#{fetch(:stage)} deploy of #{fetch(:application)} with revision/branch #{fetch(:current_revision, fetch(:branch))} failed"
}
set :slack_deploy_finished_color, 'good'
set :slack_deploy_failed_color, 'danger'
set :slack_notify_events, [:started, :finished, :failed]



namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute "sudo systemctl restart nginx"
      execute :sudo, :systemctl, :restart, :sidekiq
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
    end
  end

end
