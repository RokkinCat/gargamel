require 'active_support'
require 'active_support/core_ext/object'

class BackfillStatsWorker
  include Sidekiq::Worker

  def perform(hash)
    github_repo = GithubRepo[hash['id']]
    backfill_days = hash['backfill_days'] || 1

    (0..backfill_days).to_a.each do |i|
      date = DateTime.now - i.days
      date_issues_dataset = GithubIssue
        .filter(github_repo: github_repo)
        .filter{ created_at < date.beginning_of_day }
        .filter{ Sequel.|({closed_at: nil}, (closed_at > date )) }

      num_open_prs_on_date = date_issues_dataset.filter(is_pull_request: true).count
      num_open_issues_on_date = date_issues_dataset.filter(is_pull_request: false).count

      data = {
        github_repo_id: github_repo.id,
        date: date.to_date,
        issue_count: num_open_issues_on_date,
        pull_request_count: num_open_prs_on_date
      }

      id = DailyStat.insert_conflict(
        target: [:github_repo_id, :date],
        update: data
      ).insert(data)
    end
  end

  # def generate_issue_state(issue)
  #   user_login = issue.author_login
  #   labels = issue.labels
  #   number_of_comments = issue.comment_count
  #   created_at = issue.created_at
  #   author_association = issue.author_association
  #   days_open = ((Time.new - created_at).to_f / (60 * 60 * 24)).to_i
  
  #   # Get comment stats
  #   # comment_users_stats, number_of_core_contributors_commented = fetch_comments_stats(client, repo, issue)
  #   # author_comments_stats = comment_users_stats[user_login] || {}
  
  #   stats = {
  #     issue_number: issue.issue_number,
  #     days_open: days_open,
  #     is_core_contributor: author_association == "OWNER" || author_association == "MEMBER",
  #     number_of_comments: number_of_comments,
  #     # number_of_core_contributors_comments: number_of_core_contributors_commented,
  #     # number_of_author_comments: author_comments_stats[:number_of_comments] || 0,
  #     # days_since_last_author_comment: author_comments_stats[:days_since_last_comment] || 0
  #   }
  
  #   stats
  # end
  
  # def fetch_comments_stats(client, repo, issue)
  #   comments = client.issue_comments(repo, issue.issue_number)
  
  #   users_stats = {}
  
  #   comments.each do |comment|
  #     user_login = comment[:user][:login]
  #     created_at = comment[:created_at]
  #     author_association = comment[:author_association]
  
  #     user_stats = users_stats[user_login] || { is_core_contributor: false, number_of_comments: 0, days_since_last_comment: nil }
  #     user_stats[:number_of_comments] += 1
  #     user_stats[:is_core_contributor] = author_association == "OWNER" || author_association == "MEMBER"
      
  #     last_commented_at = ((Time.new - created_at) / (60 * 60 * 24)).to_i
  #     if user_stats[:days_since_last_comment].nil?
  #       user_stats[:days_since_last_comment] = last_commented_at
  #     elsif last_commented_at < user_stats[:days_since_last_comment]
  #       user_stats[:days_since_last_comment] = last_commented_at
  #     end
      
  #     users_stats[user_login] = user_stats
  #   end
  
  #   number_of_core_contributors = users_stats.values.select do |user_stat|
  #     user_stat[:is_core_contributor]
  #   end.length
  
  #   return users_stats, number_of_core_contributors
  # end
end