source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 2.5'

gem 'rails', '~> 5.2.3'
gem 'sassc-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'puma', '~> 3.12'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 5.0'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'honeybadger', '~> 4.0'
gem 'rails_event_store', '~> 1.0'
gem 'dry-struct'
gem 'dry-types'
gem 'skylight'

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'sqlite3'
end

group :production do
  gem 'pg'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'simplecov', require: false
  gem 'mutant-minitest', github: 'mbj/mutant', ref: '027b3d8f7508fe4e460ed999dd91f2ac3edd136b'
  gem 'mutant-license',  source: 'https://oss:7AXfeZdAfCqL1PvHm2nvDJO6Zd9UW8IK@gem.mutant.dev'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
