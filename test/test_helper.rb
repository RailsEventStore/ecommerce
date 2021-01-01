ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

ActiveRecord::Schema.verbose = false
load Rails.root.join('db/schema.rb').to_s

require 'rails/test_help'
require 'support/test_case'
require 'simplecov'
require 'mutant/minitest/coverage'


class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

SimpleCov.start
