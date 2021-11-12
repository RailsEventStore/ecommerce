require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/shipping"

module Shipping
  class Test < Infra::InMemoryTest

    def before_setup
      super
      Shipping::Configuration.new.call(cqrs)
    end
  end
end
