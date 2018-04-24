require 'sequel'
class GithubIssue < Sequel::Model
  many_to_one :github_repo

  def self.insert_conflict(args)
    DB[table_name].insert_conflict(args)
  end
end