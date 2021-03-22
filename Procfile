web: bundle exec puma -C config/puma.rb
worker: bundle exec rake jobs:work
clock: bundle exec clockwork clock.rb
clockandworker: bundle exec foreman start -f Procfile.clockandworker
