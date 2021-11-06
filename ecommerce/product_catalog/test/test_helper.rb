require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/product_catalog"

module ProductCatalog
  class Test < Infra::InMemoryTest

    def before_setup
      super()
      Configuration.new.call(cqrs)
    end
  end
end
