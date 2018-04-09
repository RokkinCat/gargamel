require 'sinatra'
require 'sidekiq'
require 'chartkick'
require 'octokit'

class App < Sinatra::Application

  if ENV['BASIC_AUTH_USERNAME'] && ENV['BASIC_AUTH_PASSWORD']
    use Rack::Auth::Basic, "Protected Area" do |username, password|
      username == ENV.fetch('BASIC_AUTH_USERNAME') && password == ENV.fetch('BASIC_AUTH_PASSWORD')
    end
  end

  configure do
    set :public_folder, File.dirname(__FILE__) + '/static'

    enable :sessions

    require_relative '../config/database'
    require_relative './models/users'
    require_relative './models/daily_stats'
    require_relative './models/github_repos'
    require_relative './models/issue_stats'
  end

  before do
    @current_user = current_user
  end

  def current_user
    user_id = session[:user_id]
    return nil unless user_id
    return User[user_id]
  end

  def protected!
    redirect '/' unless @current_user
  end

  get "/" do
    erb :index
  end

  get "/login" do
    erb :login
  end

  get "/logout" do
    session.clear
    redirect '/'
  end

  get "/github/login" do
    client = Octokit::Client.new
    url = client.authorize_url(ENV.fetch('GITHUB_CLIENT_ID'), :scope => 'user:email')
    redirect url
  end

  get '/github/callback' do
    session_code = request.env['rack.request.query_hash']['code']
    result = Octokit.exchange_code_for_token(session_code, ENV.fetch('GITHUB_CLIENT_ID'), ENV.fetch('GITHUB_CLIENT_SECRET'))
    access_token = result[:access_token]

    client = Octokit::Client.new(:access_token => access_token)
    github_user = client.user
    unless github_user
      redirect '/dashboard'
    end
    
    github_username = github_user.login
    github_id = github_user.id
    github_avatar_url = github_user.avatar_url

    user = User.where(github_id: github_id).first
    if user
      user.github_username = github_username
      user.github_avatar_url = github_avatar_url
      user.save
    else
      user = User.create(
        github_id: github_id,
        github_username: github_username,
        github_avatar_url: github_avatar_url
      )
    end

    session[:user_id] = user.id
  
    redirect '/dashboard'
  end

  get "/dashboard" do
    protected!

    @admin_mode = ENV['ADMIN_MODE'] == 'true'

    github_repos = GithubRepo.all
    @all_chart = make_all_chart(github_repos)
    @datas = github_repos.map do |github_repo|
      {
        github_repo: github_repo,
        chart: make_chart(github_repo)
      }
    end

    erb :dashboard
  end

  post "/github_repos/:id/refresh" do
    protected!
    github_repo = GithubRepo[params[:id]]

    require_relative '../workers/daily_stat_worker'
    DailyStatWorker.perform_async({id: github_repo.id})

    redirect "/dashboard"
  end

  post "/github_repos" do
    protected!
    GithubRepo.create(params)
    redirect "/dashboard"
  end

  get "/issues" do
    protected!
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