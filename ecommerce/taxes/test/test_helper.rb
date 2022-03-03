require "minitest/autorun"
require "mutant/minitest/coverage"
require "active_support/isolated_execution_state"

require_relative "../lib/taxes"

module Taxes
  class Test < Infra::InMemoryTest
    cover "Taxes*"

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
