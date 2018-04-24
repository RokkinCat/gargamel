require 'sequel'
class Team < Sequel::Model
  plugin :timestamps
  many_to_one :user
  one_to_many :github_repos
end