require_relative 'test_helper'
module Stores
  class ProductRegistrationTest < Test
    cover "Stores*"

    def test_product_should_get_registered
      store_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      assert register_product(store_id, product_id)
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      product_registered = Stores::ProductRegistered.new(data: { store_id: store_id, product_id: product_id })
      assert_events("Stores::Store$#{store_id}", product_registered) do
        register_product(store_id, product_id)
      end
    end

    private

    def register_product(store_id, product_id)
      run_command(RegisterProduct.new(store_id: store_id, product_id: product_id))
    end
  end
end
