web: bundle exec puma -p $PORT -e $RACK_ENV
worker: bundle exec sidekiq -r ./config/workers.rb
dev: foreman start devworker & bundle exec puma
devworker: bundle exec redis-server & bundle exec foreman start worker