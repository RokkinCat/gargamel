require 'sequel'
class DailyStat < Sequel::Model
  many_to_one :github_repo
end