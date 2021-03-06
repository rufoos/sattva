# config valid for current version and patch releases of Capistrano
lock "~> 3.15.0"

set :application, "give-proxy"
set :repo_url, "git@github.com:rufoos/sattva.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/app/sattva"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/thin.#{fetch(:stage)}.yml"

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/sockets'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

set :thin_config_path, -> { "#{current_path}/config/thin.#{fetch(:stage)}.yml" }

after 'deploy:publishing', 'deploy:restart'

namespace :forward_proxy do
  desc "Start forward proxy"
  task :start do
    on roles(:app) do
      config = [
        "-P #{fetch(:default_env)['FORWARD_PROXY_PORT']}",
        "-p #{shared_path}/tmp/pids/forward_proxy.pid",
        "-l #{shared_path}/log/forward_proxy.log"
      ]
      within current_path do
        puts "if [ -f #{current_path}/bin/forward-proxy ]; then #{current_path}/bin/forward-proxy #{config.join(' ')} -d; fi"
      end
    end
  end

  desc "Stop forward proxy"
  task :stop do
    on roles(:app) do
      execute "if [ -f #{shared_path}/tmp/pids/forward_proxy.pid ]; then kill -15 `cat #{shared_path}/tmp/pids/forward_proxy.pid`; fi"
    end
  end

  desc "Restart forward proxy"
  task :restart do
    on roles(:app) do
      invoke 'forward_proxy:stop'
      invoke 'forward_proxy:start'
    end
  end
end


namespace :deploy do
  task :restart do
    invoke 'thin:restart'
    invoke 'forward_proxy:restart'
  end
end
