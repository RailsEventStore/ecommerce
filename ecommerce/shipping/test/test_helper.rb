require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/shipping"

module Shipping
  class Test < Infra::InMemoryTest

    def before_setup
      super
      Shipping::Configuration.new.call(event_store, command_bus)
    end

    private

    def fake_address
      Infra::Types::PostalAddress.new(
        line_1: "Mme Anna Kowalska",
        line_2: "Ul. Bosmanska 1",
        line_3: "81-116 GDYNIA",
        line_4: "POLAND"
      )
    end
  end
end
