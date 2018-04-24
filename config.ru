require 'dotenv'
Dotenv.load '.env'

require './app/app'
require 'sidekiq/web'

require 'active_support'
require 'active_support/core_ext/object'

run Rack::URLMap.new('/' => App, '/sidekiq' => Sidekiq::Web)