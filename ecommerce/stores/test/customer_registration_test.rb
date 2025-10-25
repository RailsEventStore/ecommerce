require_relative 'test_helper'
module Stores
  class CustomerRegistrationTest < Test
    cover "Stores*"

    def test_customer_should_get_registered
      store_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      assert(register_customer(store_id, customer_id))
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      customer_registered = Stores::CustomerRegistered.new(data: { store_id: store_id, customer_id: customer_id })
      assert_events("Stores::Store$#{store_id}", customer_registered) do
        register_customer(store_id, customer_id)
      end
    end

    private

    def register_customer(store_id, customer_id)
      run_command(RegisterCustomer.new(store_id: store_id, customer_id: customer_id))
    end
  end
end
