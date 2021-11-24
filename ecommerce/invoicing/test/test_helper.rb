require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/invoicing"

module Invoicing
  class Test < Infra::InMemoryTest
    cover "Invoicing*"

    def before_setup
      super
      Configuration.new([dummy_vat_rate]).call(cqrs)
    end

    private

    def dummy_vat_rate
      Infra::Types::VatRate.new(code: "20", rate: 20)
    end
  end
end
