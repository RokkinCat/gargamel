Sequel.migration do
  up do
    create_table(:github_repos) do
      primary_key :id
      String :organization_name, null: false
      String :repo_name, null: false
      String :api_token, null: false
    end
  end

  down do
    drop_table(:github_repos)
  end
end