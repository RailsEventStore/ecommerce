require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/taxes"

module Taxes
  class Test < Infra::InMemoryTest
    cover "Taxes*"

    def before_setup
      super
      Configuration.new([dummy_vat_rate]).call(event_store, command_bus)
    end

    private

    def dummy_vat_rate
      Infra::Types::VatRate.new(code: "20", rate: 20)
    end
  end
end
