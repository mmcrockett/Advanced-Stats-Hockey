require 'bundler/capistrano'

set :user, "advancedhockeystats"
set :domain, "advancedhockeystats.mmcrockett.com"
set :applicationdir, "/home/advancedhockeystats/advancedhockeystats.mmcrockett.com"
set :application, "advancedhockeystats"
set :rails_env, :production
set :use_sudo, false

set :scm, :git
set :branch, "master"
set :repository,  "git@github.com:mmcrockett/Advanced-Stats-Hockey.git"
set :default_environment, {
  'PATH' => "/usr/lib/ruby/gems/1.8/bin:$PATH"
}

# roles (servers)
role :web, domain
role :app, domain
role :db,  domain, :primary => true
 
# deploy config
set :deploy_to, applicationdir
set :deploy_via, :export

set :keep_releases, 5

before "deploy:migrate", "deploy:copydb"
after "deploy:update_code", "deploy:migrate"
after "deploy:update", "deploy:cleanup" 

namespace :deploy do
  task :copydb do
    if (nil != previous_release)
      run("cp #{previous_release}/db/production.sqlite3 #{current_release}/db/production.sqlite3")
    end
  end

  task :start do
  end

  task :stop do
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_release}/tmp/restart.txt"
  end
end
