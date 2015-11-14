require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, '128.199.227.113'
set :deploy_to, '/var/www/mina-deploy-app'
set :repository, 'git@github.com:classpro/mina-deploy-app.git'
set :branch, 'master'
set :user, 'deploy'
set :forward_agent, true
set :term_mode, nil
#set :rail_env, 'production'



# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log']

# Optional settings:
#   set :user, 'deploy'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[sudo mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[sudo chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[sudo mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[sudo chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[sudo touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue! %[sudo touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]

  #queue %[
  #  repo_host=`echo $repo | sed -e 's/.*@//g' -e 's/:.*//g'` &&
  #  repo_port=`echo $repo | grep -o ':[0-9]*' | sed -e 's/://g'` &&
  #  if [ -z "${repo_port}" ]; then repo_port=22; fi &&
  #  sudo ssh-keyscan -p $repo_port -H $repo_host >> ~/.ssh/known_hosts
  #]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      queue 'sudo /etc/init.d/nginx restart'
      #queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
      #queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
    end
  end
end

task :restart do
  queue 'sudo /etc/init.d/nginx restart'
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
