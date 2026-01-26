require_relative 'test_helper'
module ProductCatalog
  class RegistrationTest < Test
    cover "ProductCatalog*"

    def test_product_should_get_registered
      uid = SecureRandom.uuid
      assert register_product(uid)
    end

    def test_should_not_allow_for_double_registration
      uid = SecureRandom.uuid
      assert_raises(AlreadyRegistered) do
        register_product(uid)
        register_product(uid)
      end
    end

    def test_should_publish_event
      uid = SecureRandom.uuid
      product_registered = ProductCatalog::ProductRegistered.new(data: { product_id: uid })
      assert_events("Catalog::Product$#{uid}", product_registered) do
        register_product(uid)
      end
    end

    def test_each_product_has_its_own_lifecycle
      product_1_id = SecureRandom.uuid
      product_1_registered = ProductCatalog::ProductRegistered.new(data: { product_id: product_1_id })
      product_2_id = SecureRandom.uuid
      product_2_registered = ProductCatalog::ProductRegistered.new(data: { product_id: product_2_id })

      assert_events("Catalog::Product$#{product_1_id}", product_1_registered) do
        register_product(product_1_id)
      end

      assert_events("Catalog::Product$#{product_2_id}", product_2_registered) do
        register_product(product_2_id)
      end
    end

    private

    def register_product(uid)
      run_command(RegisterProduct.new(product_id: uid))
    end

    def fake_name
      "Fake name"
    end
  end
end
