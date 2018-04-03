require 'sequel'
class IssueStat < Sequel::Model
  many_to_one :github_repo
end