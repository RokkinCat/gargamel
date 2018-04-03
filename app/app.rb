require 'sinatra'
require 'sidekiq'
require 'chartkick'

class App < Sinatra::Application

  configure do
    set :public_folder, File.dirname(__FILE__) + '/static'

    require_relative '../config/database'
    require_relative './models/daily_stats'
    require_relative './models/github_repos'
    # autoload :GithubRepo, 'models/github_repos'
  end

  get "/" do
    @datas = GithubRepo.all.map do |github_repo|
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
      adapter: "chartjs",
    )
  end

end