require "minitest/autorun" unless defined?(Mutant)
require "mutant/minitest/coverage"

require_relative "../lib/product_catalog"

module ProductCatalog
  class Test < Infra::InMemoryTest

    def before_setup
      super()
      Configuration.new(FakeNameModeration.new).call(event_store, command_bus)
    end
  end
end
