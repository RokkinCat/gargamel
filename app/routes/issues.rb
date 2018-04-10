class App < Sinatra::Application
  get "/issues" do
    teams = @current_user.teams
    if teams.first
      redirect "/teams/#{teams.first.id}/issues"
    else
      redirect "/teams"
    end
  end

  get "/teams/:id/issues" do
    protected!

    @team = @current_user.teams_dataset.where(id: params[:id]).first
    github_repos = @team.github_repos
    @issue_stats = github_repos.map do |github_repo|
      github_repo.issue_stats
    end.flatten

    erb :issues
  end
end