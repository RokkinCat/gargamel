require 'sidekiq'
require_relative './database'

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL') }
end

Sidekiq.configure_client do |config|
  config.redis = { :size => ENV.fetch('REDIS_CONNECTIONS') }
end

Sidekiq.configure_server do |config|
  config.redis = { :size => ENV.fetch('REDIS_CONNECTIONS') }
end

Dir[File.expand_path('../../workers/*.rb', __FILE__)].each { |file|require file }