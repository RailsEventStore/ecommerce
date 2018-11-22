source 'https://rubygems.org'

gem 'rails', '~> 5.2.0'
gem 'jquery-rails'
gem 'sassc-rails'
gem 'jbuilder'
gem 'sdoc', group: :doc
gem 'puma'
gem 'honeybadger', '~> 4.0'
gem 'rails_event_store',        github: 'RailsEventStore/rails_event_store'
gem 'ruby_event_store-browser', github: 'RailsEventStore/rails_event_store'

group :development do
  gem 'web-console'
end

group :development, :test do
  gem 'sqlite3'
  gem 'spring'
end

group :production do
  gem 'pg'
end

gem 'simplecov', require: false, group: :test
