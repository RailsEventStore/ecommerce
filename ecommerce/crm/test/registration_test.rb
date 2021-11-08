require_relative "test_helper"

module Crm
  class RegistrationTest < Test
    cover "Crm*"

    def test_customer_should_get_registered
      uid = SecureRandom.uuid
      register_customer(uid, fake_name)
    end

    def test_should_not_allow_for_double_registration
      uid = SecureRandom.uuid
      assert_raises(AlreadyRegistered) do
        register_customer(uid, fake_name)
        register_customer(uid, fake_name)
      end
    end

    def test_should_publish_event
      uid = SecureRandom.uuid
      customer_registered = CustomerRegistered.new(data: {customer_id: uid, name: fake_name})
      assert_events("Crm::Customer$#{uid}", customer_registered) do
        register_customer(uid, fake_name)
      end
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
