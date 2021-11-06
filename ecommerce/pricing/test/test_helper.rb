require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/pricing"

module Pricing
  class Test < Infra::InMemoryTest
    attr_reader :product_repository

    def before_setup
      super
      Configuration.new.call(cqrs)
    end
  end
end
