class App < Sinatra::Application
  get "/github/login" do
    client = Octokit::Client.new
    url = client.authorize_url(ENV.fetch('GITHUB_CLIENT_ID'), :scope => 'user,repo')
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
      user.github_oauth_access_token = access_token
      user.save
    else
      user = User.create(
        github_id: github_id,
        github_username: github_username,
        github_avatar_url: github_avatar_url,
        github_oauth_access_token: access_token
      )
    end

    session[:user_id] = user.id

    redirect '/dashboard'
  end
end