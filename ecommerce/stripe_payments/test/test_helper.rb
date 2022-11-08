require "minitest/autorun"
require "mutant/minitest/coverage"
require 'webmock/minitest'
require 'dotenv'
require_relative "../lib/payments"

module Payments
  class Test < Infra::InMemoryTest
    def before_setup
      Dotenv.load(".env.test")
      super
      Configuration.new.call(event_store, command_bus)
    end
  end
end
