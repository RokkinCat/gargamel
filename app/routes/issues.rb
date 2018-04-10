class App < Sinatra::Application
  get "/issues" do
    protected!
    github_repos = GithubRepo.all
    @issue_stats = github_repos.map do |github_repo|
      github_repo.issue_stats
    end.flatten

    erb :issues
  end
end