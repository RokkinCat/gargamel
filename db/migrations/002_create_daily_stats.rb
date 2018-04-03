Sequel.migration do
  up do
    create_table(:daily_stats) do
      primary_key :id
      foreign_key :github_repo_id, :github_repos
      Integer :issue_count, null: false, default: 0
      Integer :pull_request_count, null: false, default: 0
      Date :date, default: Sequel::CURRENT_TIMESTAMP
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      unique [:github_repo_id, :date]
    end
  end

  down do
    drop_table(:daily_stats)
  end
end