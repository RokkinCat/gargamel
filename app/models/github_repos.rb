require 'sequel'
class GithubRepo < Sequel::Model
  one_to_many :daily_stats
  one_to_many :issue_stats
end