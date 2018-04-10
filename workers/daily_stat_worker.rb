require 'octokit'

class DailyStatWorker
  include Sidekiq::Worker

  def perform(hash)

    github_repo = GithubRepo[hash['id']]
    repo_slug = "#{github_repo.organization_name}/#{github_repo.repo_name}"
    access_token = github_repo.access_token

    client = Octokit::Client.new(:access_token => access_token)
    client.auto_paginate = true

    issues = client.issues(repo_slug)
    pull_requests = issues.select do |issue|
      !issue.pull_request.nil?
    end

    pull_request_count = pull_requests.length
    issue_count = issues.length - pull_request_count

    # issues_stats = issues.map do |issue|
    #   fetch_issue_stats(repo, issue)
    # end

    daily_stats = {
      name: repo_slug,
      # issues_stats: issues_stats,
      issue_count: issue_count,
      pull_request_count: pull_request_count
    }

    daily_stat = DailyStat.where(github_repo: github_repo, date: Date.today).first
    if daily_stat
      daily_stat.issue_count = issue_count
      daily_stat.pull_request_count = pull_request_count
      daily_stat.save
    else
      DailyStat.create(
        github_repo: github_repo,
        issue_count: issue_count,
        pull_request_count: pull_request_count
      )
    end
  end
end