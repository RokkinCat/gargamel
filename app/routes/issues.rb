class App < Sinatra::Application
  get "/issues" do
    protected!

    team = get_team!
    if team
      redirect "/teams/#{team.id}/issues"
    else
      redirect "/teams"
    end
  end

  get "/teams/:id/issues" do
    protected!

    @teams = @current_user.teams
    @team = select_team!(params[:id])

    @team = @current_user.teams_dataset.where(id: params[:id]).first
    github_repos = @team.github_repos
    @issue_stats = github_repos.map do |github_repo|
      github_repo.issue_stats
    end.flatten

    erb :issues
  end
end