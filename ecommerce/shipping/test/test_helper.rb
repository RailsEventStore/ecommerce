require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../../pricing/lib/pricing"
require_relative "../../shipping/lib/shipping"

module Shipping
  class Test < Infra::InMemoryTest

    def before_setup
      super
      Shipping::Configuration.new.call(cqrs)
    end
  end
end
