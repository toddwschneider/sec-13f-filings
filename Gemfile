source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.2'

gem 'rails', '~> 6.1.4'

gem 'bootsnap', '>= 1.4.4', require: false
gem 'clockwork', '~> 2.0'
gem 'delayed_job_active_record', '~> 4.1'
gem 'down', '~> 5.2'
gem 'foreman', '~> 0.87'
gem 'hashie', '~> 4.1'
gem 'httparty', '~> 0.18'
gem 'kaminari', '~> 1.2'
gem 'nokogiri', '~> 1.11'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'
gem 'rack-timeout', '~> 0.6'
gem 'scenic', '~> 1.5'
gem 'webpacker', '~> 5.0'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'
end

group :development do
  gem 'awesome_print'
  gem 'get_process_mem'
  gem 'listen', '~> 3.3'
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'spring'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
