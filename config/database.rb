require 'sequel'
DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
Sequel::Model.plugin :timestamps