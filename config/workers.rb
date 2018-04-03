require 'sidekiq'
require_relative './database'

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL') }
end

Sidekiq.configure_client do |config|
  config.redis = { :size => 30 }
end

Sidekiq.configure_server do |config|
  config.redis = { :size => 30 }
end

Dir[File.expand_path('../../workers/*.rb', __FILE__)].each { |file|require file }