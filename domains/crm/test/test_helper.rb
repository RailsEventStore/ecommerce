require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/crm"

module Crm
  class Test < Infra::InMemoryTest
    def before_setup
      super()
      Configuration.new.call(event_store, command_bus)
    end

    private

    def register_customer(uid, name)
      run_command(RegisterCustomer.new(customer_id: uid, name: name))
    end

    def fake_name
      "Fake name"
    end
  end
end
