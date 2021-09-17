require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/ordering"
require_relative "../../product_catalog/lib/product_catalog"
require_relative "../../pricing/lib/pricing"
require_relative "../../crm/lib/crm"

module Ordering
  class Test < Infra::InMemoryTest
    def before_setup
      super
      @number_generator = FakeNumberGenerator.new
      Configuration.new(cqrs, event_store, -> { @number_generator }).call

      ProductCatalog::Configuration.new(cqrs).call
      Pricing::Configuration.new(cqrs, event_store).call
      Crm::Configuration.new(cqrs, Crm::InMemoryCustomerRepository.new).call
    end
  end
end
