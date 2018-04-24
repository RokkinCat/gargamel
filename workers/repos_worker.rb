require 'octokit'

class ReposWorker
  include Sidekiq::Worker

  def perform(hash)
    github_repos = GithubRepo.all
    github_repos.each do |github_repo|
      IssuesWorker.perform_async({id: github_repo.id, backfill: false})

      # DailyStatWorker.perform_async({id: github_repo.id})
      # IssueStatWorker.perform_async({id: github_repo.id})
    end
  end
end