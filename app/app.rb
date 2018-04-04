require 'sinatra'
require 'sidekiq'
require 'chartkick'

class App < Sinatra::Application

  if ENV['BASIC_AUTH_USERNAME'] && ENV['BASIC_AUTH_PASSWORD']
    use Rack::Auth::Basic, "Protected Area" do |username, password|
      username == ENV.fetch('BASIC_AUTH_USERNAME') && password == ENV.fetch('BASIC_AUTH_PASSWORD')
    end
  end

  configure do
    set :public_folder, File.dirname(__FILE__) + '/static'

    require_relative '../config/database'
    require_relative './models/daily_stats'
    require_relative './models/github_repos'
    require_relative './models/issue_stats'
    # autoload :GithubRepo, 'models/github_repos'
  end

  get "/" do
    @admin_mode = ENV['ADMIN_MODE'] == 'true'

    github_repos = GithubRepo.all
    @all_chart = make_all_chart(github_repos)
    @datas = github_repos.map do |github_repo|
      {
        github_repo: github_repo,
        chart: make_chart(github_repo)
      }
    end

    erb :index
  end

  post "/github_repos/:id/refresh" do
    github_repo = GithubRepo[params[:id]]

    puts "do: #{github_repo.id}"

    require_relative '../workers/daily_stat_worker'
    DailyStatWorker.perform_async({id: github_repo.id})

    redirect "/"
  end

  post "/github_repos" do
    GithubRepo.create(params)
    redirect "/"
  end

  get "/issues" do
    github_repos = GithubRepo.all
    @issue_stats = github_repos.map do |github_repo|
      github_repo.issue_stats
    end.flatten

    erb :issues
  end

  def make_all_chart(github_repos)
    all_pull_request_map = {}
    all_issue_map = {}

    repo_data = github_repos.map do |github_repo|
      daily_stats = github_repo.daily_stats
      pull_request_series = daily_stats.map do |daily_stat|
        all_pull_request_for_date = all_pull_request_map[daily_stat.date] || 0
        all_pull_request_for_date += daily_stat.pull_request_count
        all_pull_request_map[daily_stat.date] = all_pull_request_for_date

        [daily_stat.date, daily_stat.pull_request_count]
      end
      issues_series = daily_stats.map do |daily_stat|
        all_issue_for_date = all_issue_map[daily_stat.date] || 0
        all_issue_for_date += daily_stat.issue_count
        all_issue_map[daily_stat.date] = all_issue_for_date

        [daily_stat.date, daily_stat.issue_count]
      end

      repo_slug = "#{github_repo.organization_name}/#{github_repo.repo_name}"
      [
        {name: "#{repo_slug} - Pull Requests", data:  pull_request_series},
        {name: "#{repo_slug} - Issues", data: issues_series}
      ]
    end.flatten

    all_pull_request_series_data = all_pull_request_map.keys.sort.map do |key|
      [key, all_pull_request_map[key]]
    end
    all_issue_series_data = all_issue_map.keys.sort.map do |key|
      [key, all_issue_map[key]]
    end

    data = [
      {name: "All Pull Requests", data:  all_pull_request_series_data},
      {name: "All Issues", data: all_issue_series_data}
    ] + repo_data
    line_chart(data, adapter: "chartjs", height: "500px")
  end

  def make_chart(github_repo)
    daily_stats = github_repo.daily_stats

    pull_request_series = daily_stats.map do |daily_stat|
      [daily_stat.date, daily_stat.pull_request_count]
    end
    issues_series = daily_stats.map do |daily_stat|
      [daily_stat.date, daily_stat.issue_count]
    end

    line_chart(
      [
        {name: "Pull Requests", data:  pull_request_series},
        {name: "Issues", data: issues_series}
      ], 
      adapter: "chartjs"
    )
  end

end