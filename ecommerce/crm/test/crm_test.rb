require_relative 'test_helper'

module Crm
  class CrmTest < Ecommerce::InMemoryTestCase

    cover 'Crm*'

    def test_customer_should_get_registered
      uid = SecureRandom.uuid
      register_customer(uid, fake_name)
      assert_not_nil(customer_registered = Customer.find(uid))
      assert_equal(customer_registered.name, fake_name)
    end

    def test_should_not_allow_for_double_registration
      uid = SecureRandom.uuid
      assert_raises(Customer::AlreadyRegistered) do
        2.times { register_customer(uid, fake_name) }
      end
    end

    private

    def register_customer(uid, name)
      run_command(RegisterCustomer.new(customer_id: uid, name: name))
    end

    def fake_name
      'Fake name'
    end
  end
end

