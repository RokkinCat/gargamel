Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
  
      Integer :github_id
      String :github_username
      String :github_avatar_url
      String :github_oauth_access_token
      String :github_access_token
  
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
  
  down do
    drop_table(:users)
  end
end