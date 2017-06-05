server "advancedhockeystats.mmcrockett.com", user: "washingrvingrails", roles: %w{app db web}

set :deploy_to, File.join("","home","washingrvingrails","advancedhockeystats.mmcrockett.com")
set :tmp_dir, File.join("","home","washingrvingrails","tmp")
