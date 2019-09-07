# Change to match your CPU core count
workers 1

# Min and Max threads per worker
threads 1, 6

app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/shared"

# Default to production
rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env
control_app_url = "tcp://127.0.0.1:3000"
activate_control_app control_app_url, { auth_token: ENV.fetch("CONTROL_APP_TOKEN") { '12345' } }
# Logging
stdout_redirect "#{shared_dir}/logs/puma.stdout.log", "#{shared_dir}/logs/puma.stderr.log", true

# Set master PID and state locations
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"
activate_control_app

on_worker_boot do
  require "active_record"
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
end
