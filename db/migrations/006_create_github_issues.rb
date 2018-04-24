Sequel.migration do
  up do
    create_table(:github_issues) do
      primary_key :id
      foreign_key :github_repo_id, :github_repos

      # Actual issue fields
      Integer :issue_id, null: false
      Integer :issue_number, null: false

      TrueClass :is_pull_request, default: false

      String :title
      String :body 
      String :author_association

      Jsonb :labels
      String :state
      Integer :comment_count

      Integer :author_id
      String :author_login

      Jsonb :raw_response

      DateTime :created_at
      DateTime :updated_at
      DateTime :closed_at

      unique [:github_repo_id, :issue_id]
    end
  end

  down do
    drop_table(:github_issues)
  end
end