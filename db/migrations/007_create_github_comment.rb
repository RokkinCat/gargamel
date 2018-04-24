Sequel.migration do
  up do
    create_table(:github_comments) do
      primary_key :id
      foreign_key :github_issue_id, :github_issues

      Integer :comment_id, null: false

      String :body 
      String :author_association

      Integer :author_id
      String :author_login

      Jsonb :raw_response

      DateTime :created_at
      DateTime :updated_at

      unique [:github_issue_id, :comment_id]
    end
  end

  down do
    drop_table(:github_comments)
  end
end