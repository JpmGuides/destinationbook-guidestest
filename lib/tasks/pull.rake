desc "Pulls the database from heroku and stores it into db/backups/"
task :pull do
  heroku_env = "production"
  app_name = "destinationbook"
  system "heroku pgbackups:capture --expire --app #{app_name}"
  backup = `heroku pgbackups --app #{app_name}`.split("\n").last.split(" ").first
  system "mkdir -p db/backups/#{heroku_env}"
  file = "db/backups/#{heroku_env}/#{backup}.dump"
  url = `heroku pgbackups:url --app #{app_name} #{backup}`.chomp
  system "wget", url, "-O", file
  system "rake db:drop db:create"
  system "pg_restore --verbose --clean --no-acl --no-owner -h localhost -d #{app_name}_development #{file}"
end
