# config valid only for current version of Capistrano
lock '3.6.0'

set :application, 'advancedhockeystats'
set :repo_url, 'git@github.com:mmcrockett/Advanced-Stats-Hockey.git'

append :linked_dirs, "log"
append :linked_dirs, "tmp"
append :linked_files, ".htaccess"

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Check if db exists and move to shared.'
  task :check_sqlite_db do
    on roles(:app) do
      db_name = File.join("db", "#{fetch(:rails_env)}.sqlite3")
      curr_db = current_path.join(db_name)
      link_db = shared_path.join(db_name)

      if (false == test("[ -f #{link_db} ]"))
        if (true == test("[ -f #{curr_db} ]"))
          if (false == test("[ -d #{shared_path.join('db')} ]"))
            execute :mkdir, shared_path.join('db')
          end

          execute :cp, curr_db, link_db

          append :linked_files, db_name
        end
      else
        append :linked_files, db_name
      end
    end
  end

  desc 'Create secret'
  task :create_secret do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # Test that it works so we don't create bad file and it shows error.
          execute(:rake, 'secret')

          # Now run for real
          execute(:rake, 'secret', '>', fetch(:secret_file))
        end
      end
    end
  end

  desc 'Check if secret exists and move to shared.'
  task :check_secret do
    on roles(:app), in: :sequence, wait: 5 do
      secret_file = fetch(:secret_file)
      curr_secret = current_path.join(secret_file)
      link_secret = shared_path.join(secret_file)

      if (false == test("[ -f #{link_secret} ]"))
        if (true == test("[ -f #{curr_secret} ]"))
          if (false == test("[ -d #{shared_path.join('config')} ]"))
            execute :mkdir, shared_path.join('config')
          end

          execute :cp, curr_secret, link_secret

          append :linked_files, secret_file
        else
          after("deploy:published", "deploy:create_secret")
        end
      else
        append :linked_files, secret_file
      end
    end
  end

  before "check:linked_files", :check_sqlite_db
  after :publishing, :restart
  before "check:linked_files", :check_sqlite_db
  before "check:linked_files", :check_secret
end
