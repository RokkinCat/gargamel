require 'octokit'

class CommentsWorker
  include Sidekiq::Worker

  def perform(hash)
    github_issue = GithubIssue[hash['id']]

    github_repo = github_issue.github_repo
    repo_slug = "#{github_repo.organization_name}/#{github_repo.repo_name}"

    client = github_repo.team.user.github_client
    client.auto_paginate = true

    comments = client.issue_comments(repo_slug, github_issue.issue_number)
    comments.each do |comment|
      data = {
        github_issue_id: github_issue.id,
        comment_id: comment.id,
        body: comment.body,
        author_association: comment.author_association,
        author_id: comment.user.id,
        author_login: comment.user.login,
        created_at: comment.created_at,
        updated_at: comment.updated_at,
        raw_response: Sequel.pg_jsonb(comment.to_hash)
      }

      GithubComment.insert_conflict(
        target: [:github_issue_id, :comment_id], 
        update: data
      ).insert(data)
    end

  end
end