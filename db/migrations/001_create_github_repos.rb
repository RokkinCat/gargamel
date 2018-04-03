Sequel.migration do
  up do
    create_table(:github_repos) do
      primary_key :id
      String :organization_name, null: false
      String :repo_name, null: false
      String :access_token, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:github_repos)
  end
end