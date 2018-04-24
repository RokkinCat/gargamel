require 'sequel'
class GithubComment < Sequel::Model
  many_to_one :github_issue

  def self.insert_conflict(args)
    DB[table_name].insert_conflict(args)
  end
end