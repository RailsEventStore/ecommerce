require_relative "test_helper"

module Crm
  class CrmTest < Test
    cover "Crm*"

    def test_customer_should_get_registered
      register_customer(uuid = SecureRandom.uuid, fake_name)

      refute_nil customer_registered = customer_repository.find(uuid)
      assert_equal fake_name, customer_registered.name
    end

    def test_should_not_allow_for_double_registration
      uuid = SecureRandom.uuid

      assert_raises(Customer::AlreadyRegistered) do
        register_customer(uuid, fake_name)
        register_customer(uuid, fake_name)
      end
    end

    private

    def register_customer(uid, name)
      run_command(RegisterCustomer.new(customer_id: uid, name: name))
    end

    def fake_name
      "Fake Name"
    end
  end
end
