namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require 'dotenv'
    Dotenv.load ".env"

    require "sequel"
    Sequel.extension :migration
    db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "db/migrations")
    end
  end
end

namespace :garg do
  desc "Run daily stats"
  task :daily do |t, args|
    require 'dotenv'
    Dotenv.load ".env"

    require "sequel"
    Sequel.connect(ENV.fetch("DATABASE_URL"))

    require 'sidekiq'
    require_relative './workers/repos_worker'
    ReposWorker.perform_async({})
  end
end