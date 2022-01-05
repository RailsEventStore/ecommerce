require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/invoicing"

module Invoicing
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(cqrs)
    end

    private

    def set_product_name_displayed(product_id, name_displayed)
      run_command(SetProductNameDisplayedOnInvoice.new(product_id: product_id, name_displayed: name_displayed))
    end
  end
end
