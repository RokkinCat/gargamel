require 'sequel'
class GithubRepo < Sequel::Model
  plugin :timestamps
  one_to_many :daily_stats
  one_to_many :issue_stats
  many_to_one :team

  def after_save
    super
    db.after_commit do
      IssuesWorker.perform_async(id: id, backfill: true)
    end
  end
end