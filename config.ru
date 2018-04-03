require 'dotenv'
Dotenv.load '.env'

require './app/app'
require 'sidekiq/web'

run Rack::URLMap.new('/' => App, '/sidekiq' => Sidekiq::Web)