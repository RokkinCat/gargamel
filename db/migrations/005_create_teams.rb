Sequel.migration do
  up do
    create_table(:teams) do
      primary_key :id
      foreign_key :user_id, :users

      String :name
  
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
    alter_table(:github_repos) do
      add_foreign_key :team_id, :teams
      drop_column :access_token
    end
  end
  
  down do
    alter_table(:github_repos) do
      drop_foreign_key :team_id
      add_column :access_token, String
    end
    drop_table(:teams)
  end
end