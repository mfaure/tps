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

ENV['to'] ||= "staging"
raise "Bad to=#{+ENV['to']}" if !["staging", "production"].include?(ENV['to'])

raise "missing domain, run with 'rake deploy domain=xxx.xxx.xxx.xxx'" if ENV['domain'].nil?

set :domain, ENV['domain']

set :repository, 'https://github.com/betagouv/tps.git'
set :deploy_to, '/var/www/ds'
set :user, 'deploy'
set :branch, 'puma'

print "Deploy to #{ENV['to']} environment branch #{branch}\n"

set :rails_env, 'production'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, [
  '.env',
  'log',
  'uploads',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'public/system',
  'public/uploads'
]

set :rbenv_path, "/home/deploy/.rbenv/bin/rbenv"

set :forward_agent, true # SSH forward_agent.
#
# # This task is the environment that is loaded for most commands, such as
# # `mina deploy` or `mina rake`.
# task :setup => :environment do
#   queue! %[mkdir -p "#{deploy_to}/shared/log"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/bin"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/bin"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/tmp/cache"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/cache"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/tmp/sockets"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/sockets"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/public/system"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/system"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/public/uploads"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/uploads"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/config"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/app"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/app"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/views/layouts"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/views/layouts"]
#
#   queue! %[mkdir -p "#{deploy_to}/shared/config/locales/dynamics"]
#   queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config/locales/dynamics"]
# end

namespace :yarn do
  desc "Install package dependencies using yarn."
  task :install do
    queue %{
      echo "-----> Installing package dependencies using yarn"
      #{echo_cmd %[yarn install --non-interactive]}
    }
  end
end

namespace :rails do
  desc "Run deploy tasks."
  task :after_party do
    queue %{
      echo "-----> Running deploy tasks"
      #{echo_cmd %[bundle exec rake after_party:run]}
    }
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  # queue 'export PATH=$PATH:/usr/local/rbenv/bin:/usr/local/rbenv/shims'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    # invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'yarn:install'
    invoke :'rails:db_migrate'
    invoke :'rails:after_party'
    invoke :'rails:assets_precompile:force'

    to :launch do
      queue "/etc/init.d/#{user} upgrade "
      queue! %[sudo service delayed_job_#{user!} start]

      # If you are deploying a review app on a fresh testing environment,
      # now can be a good time to seed the database.
    end
  end
end
# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
