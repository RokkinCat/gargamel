require 'sequel'
class IssueStat < Sequel::Model
  plugin :timestamps
  many_to_one :github_repo
end