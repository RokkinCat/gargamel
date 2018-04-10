require 'chartkick'

class App < Sinatra::Application
  get "/dashboard" do
    teams = @current_user.teams
    if teams.first
      redirect "/teams/#{teams.first.id}"
    else
      redirect "/teams"
    end
  end

  get "/teams/:id" do
    protected!

    @team = @current_user.teams_dataset.where(id: params[:id]).first

    github_repos = @team.github_repos
    @all_chart = make_all_chart(github_repos)
    @datas = github_repos.map do |github_repo|
      {
        github_repo: github_repo,
        chart: make_chart(github_repo)
      }
    end

    erb :team_dashboard
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