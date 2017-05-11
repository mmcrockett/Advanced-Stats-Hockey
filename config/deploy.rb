# config valid only for current version of Capistrano
lock '3.6.0'

set :application, 'advancedhockeystats'
set :repo_url, 'git@github.com:mmcrockett/Advanced-Stats-Hockey.git'
set :secret_file, File.join("config", "secret.token")

append :linked_dirs, "log"
append :linked_dirs, "tmp"
append :linked_files, fetch(:secret_file)

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Create secret file if missing'
  task :create_secret do
    on roles(:app), in: :sequence, wait: 5 do
      secret_file = shared_path.join(fetch(:secret_file))

      if (false == test("[ -f #{secret_file} ]"))
        execute(:rake, 'secret', '>', secret_file)
      else
        info("Secret file already exists. Doing nothing.")
      end
    end
  end


  after :publishing, :restart
  before "assets:precompile", :create_secret

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      Here we can do anything such as:
      within release_path do
        execute :rake, 'cache:clear'
      end
    end
  end
end
