Sequel.migration do
  up do
    create_table(:issue_stats) do
      primary_key :id
      foreign_key :github_repo_id, :github_repos

      String :issue_number, null: false

      Integer :days_open
      TrueClass :is_core_contributor, default: false
      Integer :number_of_comments
      Integer :number_of_core_contributors_comments
      Integer :number_of_author_comments
      Integer :days_since_last_author_comment

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP

      unique [:github_repo_id, :issue_number]
    end
  end

  down do
    drop_table(:issue_stats)
  end
end