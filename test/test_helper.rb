ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'codeclimate-test-reporter'
require_relative 'lib/command_handlers/test_case.rb'
CodeClimate::TestReporter.start
