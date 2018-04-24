require 'octokit'

class IssuesWorker
  include Sidekiq::Worker

  def perform(hash)
    backfill_days = hash['backfill_days'] || 30

    github_repo = GithubRepo[hash['id']]
    repo_slug = "#{github_repo.organization_name}/#{github_repo.repo_name}"

    client = github_repo.team.user.github_client
    client.auto_paginate = true

    backfill_until = (DateTime.now - backfill_days.days).iso8601

    issues = client.issues(repo_slug, state: "all", since: backfill_until)
    github_issues = issues.map do |issue|
      data = {
        github_repo_id: github_repo.id,
        issue_id: issue.id,
        issue_number: issue.number,
        is_pull_request: !issue.pull_request.nil?,
        title: issue.title,
        body: issue.body,
        author_association: issue.author_association,
        labels: Sequel.pg_jsonb(issue.labels.map(&:name)),
        state: issue.state,
        comment_count: issue.comments,
        author_id: issue.user.id,
        author_login: issue.user.login,
        created_at: issue.created_at,
        updated_at: issue.updated_at,
        closed_at: issue.closed_at,
        raw_response: Sequel.pg_jsonb(issue.to_hash)
      }

      id = GithubIssue.insert_conflict(
        target: [:github_repo_id, :issue_id], 
        update: data
      ).insert(data)

      GithubIssue[id]
    end

    github_issues.select do |github_issue|
      github_issue.state == 'open'
    end.each do |github_issue|
      CommentsWorker.perform_async(id: github_issue.id)
    end
  end
end