# config valid only for current version of Capistrano
lock '3.6.0'

set :application, 'advancedhockeystats'
set :repo_url, 'git@github.com:mmcrockett/Advanced-Stats-Hockey.git'

append :linked_dirs, "log"
append :linked_dirs, "tmp"
append :linked_files, ".htaccess"
append :linked_files, File.join('db', 'production.sqlite3')

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart
end
