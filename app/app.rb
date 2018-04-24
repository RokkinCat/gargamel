require 'sinatra'
require 'sidekiq'
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

  def select_team!(team_id)
    team = @current_user.teams_dataset.where(id: params[:id]).first
    session[:team_id] = team.id
    puts "set session[:team_id]: #{session[:team_id]}"
    team
  end

  def get_team!
    puts "get session[:team_id]: #{session[:team_id]}"
    team = @current_user.teams_dataset.where(id: session[:team_id]).first if session[:team_id]
    team = @current_user.teams.first unless team

    team
  end

  get "/" do
    erb :index
  end

  post "/github_repos/:id/refresh" do
    protected!
    github_repo = GithubRepo[params[:id]]

    DailyStatWorker.perform_async({id: github_repo.id})

    redirect "/dashboard"
  end
end

require_relative '../config/database'
require_relative 'models/init'
require_relative 'routes/init'
require_relative '../workers/init'