require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv' # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

raise "missing domain, run with 'rake deploy domain=xxx.xxx.xxx.xxx'" if ENV['domain'].nil?

set :domain, ENV['domain']

set :repository, 'https://github.com/betagouv/tps.git'
deploy_to = '/var/www/ds'
set :deploy_to, deploy_to
set :user, 'deploy'
branch = 'puma'
set :branch, branch

print "Deploy to #{ENV['domain']}, branch : #{branch}\n"

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, [
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets'
]

set :rbenv_path, "/home/deploy/.rbenv/bin/rbenv"

set :forward_agent, true # SSH forward_agent.
#
# # This task is the environment that is loaded for most commands, such as
# # `mina deploy` or `mina rake`.
task :setup do
  command %[mkdir -p "#{deploy_to}/shared/log"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  command %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]

  command %[mkdir -p "#{deploy_to}/shared/tmp/cache"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/cache"]

  command %[mkdir -p "#{deploy_to}/shared/tmp/sockets"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/sockets"]

  command %[ln -s "#{deploy_to}/current" "/home/deploy/current"]
end

namespace :yarn do
  desc "Install package dependencies using yarn."
  task :install do
    command %{
      echo "-----> Installing package dependencies using yarn"
      #{echo_cmd %[yarn install --non-interactive]}
    }
  end
end

namespace :rails do
  desc "Run deploy tasks."
  task :after_party do
    command %{
      echo "-----> Running deploy tasks"
      #{echo_cmd %[bundle exec rake after_party:run]}
    }
  end
end

namespace :service do
  desc "Manage services."
  task :restart_puma do
    command %{
      echo "-----> Restarting puma service"
      #{echo_cmd %[sudo systemctl restart puma]}
    }
  end
  task :restart_delayed_job do
    command %{
      echo "-----> Restarting delayed_job service"
      #{echo_cmd %[sudo systemctl restart delayed_job]}
    }
  end
end

desc "Deploys the current version to the server."
task :deploy do
  command 'export PATH=$PATH:/home/deploy/.rbenv/bin:/home/deploy/.rbenv/shims'
  command 'export SECRET_KEY_BASE="fake_secret_to_precompile"'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'yarn:install'
    invoke :'rails:db_migrate'
    invoke :'rails:after_party'
    invoke :'rails:assets_precompile'

    on :launch do
      invoke :'service:restart_puma'
      invoke :'service:restart_delayed_job'
    end
  end
end
