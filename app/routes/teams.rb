class App < Sinatra::Application
  get "/teams" do
    protected!

    @teams = @current_user.teams

    erb :teams
  end

  post "/teams" do
    protected!
    Team.create(user_id: @current_user.id, name: params[:name])
    redirect "/teams"
  end

  get "/teams/:id/edit" do
    protected!

    @team = @current_user.teams_dataset.where(id: params[:id]).first

    @github_repos = []

    client = @current_user.github_client
    client.auto_paginate = true
    repos = client.repositories(type: 'all')

    @repo_names = repos.map do |repo|
      "#{repo.owner.login}/#{repo.name}"
    end

    erb :team
  end

  post "/teams/:id/github_repos" do
    protected!

    team_id = params[:id]
    full_repo_name = params[:full_repo_name]

    repo_parts = full_repo_name.split('/')

    github_repo = GithubRepo.create(
      team_id: team_id,
      organization_name: repo_parts.first,
      repo_name: repo_parts.last,
    )
    DailyStatWorker.perform_async({id: github_repo.id})

    redirect "/dashboard"
  end
end