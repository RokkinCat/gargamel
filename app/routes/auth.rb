class App < Sinatra::Application
  get "/login" do
    erb :login
  end

  get "/logout" do
    session.clear
    redirect '/'
  end
end