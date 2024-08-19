require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/taxes"

module Taxes
  class Test < Infra::InMemoryTest
    cover "Taxes*"

    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end
  end
end
