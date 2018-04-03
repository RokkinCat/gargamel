require 'sinatra'
require 'chartkick'

class App < Sinatra::Application

  configure do
    set :public_folder, File.dirname(__FILE__) + '/static'

    require_relative '../db/config'
    require_relative './models/github_repos'
    # autoload :GithubRepo, 'models/github_repos'
  end

  get "/" do
    @datas = GithubRepo.all.map do |github_repo|
      {
        github_repo: github_repo,
        chart: make_chart
      }
    end

    erb :index
  end

  post "/github_repos" do
    GithubRepo.create(params)
    redirect "/"
  end

  def make_chart
    line_chart(
      [
        {name: "Pull Requests", data:  [
          ["3/1", 3],
          ["3/2", 4],
          ["3/3", 5],
          ["3/4", 6],
          ["3/5", 7],
          ["3/6", 8]
        ]},
        {name: "Issues", data: [
          ["3/1", 9],
          ["3/2", 8],
          ["3/3", 7],
          ["3/4", 6],
          ["3/5", 5],
          ["3/6", 4]
        ]}
      ], 
      adapter: "chartjs",
    )
  end

end