require 'sequel'
class GithubIssue < Sequel::Model
  many_to_one :github_repo
  one_to_many :github_comments

  def self.insert_conflict(args)
    DB[table_name].insert_conflict(args)
  end
end