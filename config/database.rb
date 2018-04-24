require 'sequel'
DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
DB.extension :pg_array, :pg_json