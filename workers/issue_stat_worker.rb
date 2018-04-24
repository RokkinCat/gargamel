require 'octokit'

class IssueStatWorker
  include Sidekiq::Worker

  def perform(hash)
    github_issue = GithubIssue[hash['id']]
    github_repo = github_issue.github_repo
    repo_slug = "#{github_repo.organization_name}/#{github_repo.repo_name}"

    client = github_repo.team.user.github_client
    client.auto_paginate = true

    issue_hash = fetch_issue_stats(client, repo_slug, github_issue)
    issue_hash[:github_repo] = github_repo

    puts issue_hash

    # Need to upsert
    # IssueStat.create(issue_hash)

  end

  def fetch_issue_stats(client, repo, issue)
    user_login = issue.author_login
    labels = issue.labels
    number_of_comments = issue.comment_count
    created_at = issue.created_at
    author_association = issue.author_association
    days_open = ((Time.new - created_at).to_f / (60 * 60 * 24)).to_i
  
    # Get comment stats
    # comment_users_stats, number_of_core_contributors_commented = fetch_comments_stats(client, repo, issue)
    # author_comments_stats = comment_users_stats[user_login] || {}
  
    stats = {
      issue_number: issue.issue_number,
      days_open: days_open,
      is_core_contributor: author_association == "OWNER" || author_association == "MEMBER",
      number_of_comments: number_of_comments,
      # number_of_core_contributors_comments: number_of_core_contributors_commented,
      # number_of_author_comments: author_comments_stats[:number_of_comments] || 0,
      # days_since_last_author_comment: author_comments_stats[:days_since_last_comment] || 0
    }
  
    stats
  end
  
  def fetch_comments_stats(client, repo, issue)
    comments = client.issue_comments(repo, issue.issue_number)
  
    users_stats = {}
  
    comments.each do |comment|
      user_login = comment[:user][:login]
      created_at = comment[:created_at]
      author_association = comment[:author_association]
  
      user_stats = users_stats[user_login] || { is_core_contributor: false, number_of_comments: 0, days_since_last_comment: nil }
      user_stats[:number_of_comments] += 1
      user_stats[:is_core_contributor] = author_association == "OWNER" || author_association == "MEMBER"
      
      last_commented_at = ((Time.new - created_at) / (60 * 60 * 24)).to_i
      if user_stats[:days_since_last_comment].nil?
        user_stats[:days_since_last_comment] = last_commented_at
      elsif last_commented_at < user_stats[:days_since_last_comment]
        user_stats[:days_since_last_comment] = last_commented_at
      end
      
      users_stats[user_login] = user_stats
    end
  
    number_of_core_contributors = users_stats.values.select do |user_stat|
      user_stat[:is_core_contributor]
    end.length
  
    return users_stats, number_of_core_contributors
  end
end