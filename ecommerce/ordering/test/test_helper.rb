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
      number_generator = FakeNumberGenerator.new
      [
        Configuration.new(-> { number_generator }),
        ProductCatalog::Configuration.new,
        Pricing::Configuration.new,
        Crm::Configuration.new
      ].each { |c| c.call(cqrs) }
    end
  end
end
