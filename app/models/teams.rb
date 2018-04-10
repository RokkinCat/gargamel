require 'sequel'
class Team < Sequel::Model
  many_to_one :user
  one_to_many :github_repos
end