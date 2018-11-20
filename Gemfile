source 'https://rubygems.org'
gem 'codeclimate-test-reporter', group: :test, require: nil

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2'
# Use SCSSC for stylesheets
gem 'sassc-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'bootstrap-sass'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'puma'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'
end

group :test do
  gem 'rspec-core'
end

group :development, :test do
  gem 'byebug'
  gem 'pry'
  gem 'sqlite3'
  gem 'spring'
end

group :production do
  gem 'pg'
end

gem 'rails_event_store', github: 'RailsEventStore/rails_event_store'
