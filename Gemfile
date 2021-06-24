source 'https://rubygems.org'

ruby '2.7.2'

gem 'rails', '~> 6.1.0'
gem 'puma', '~> 5.3'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'honeybadger', '~> 4.0'
gem 'pg'
gem 'dry-struct'
gem 'dry-types'
gem 'skylight'
gem 'rails_event_store', '~> 2.1.0', require: %w[aggregate_root rails_event_store]
gem 'ruby_event_store-transformations'
gem 'activeadmin'

group :development do
  gem 'web-console', '>= 4.1.0'
  gem 'listen', '~> 3.3'
end

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'
end

group :test do
  # gem 'capybara', '>= 3.34'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'simplecov', require: false
  gem 'mutant-minitest'
  gem 'mutant-license',  source: 'https://oss:7AXfeZdAfCqL1PvHm2nvDJO6Zd9UW8IK@gem.mutant.dev'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
