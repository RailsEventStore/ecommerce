require 'test_helper'

module ProductCatalog
  class ProductCatalogTest < ActiveSupport::TestCase

    cover 'ProductCatalog*'

    def test_product_should_get_registered
      uid = SecureRandom.uuid
      register_product(uid, fake_name)
      assert_not_nil product_registered = Product.find_by(uid: uid)
      assert_equal product_registered.name, fake_name
    end

    def test_should_not_allow_for_double_registration
      uid = SecureRandom.uuid
      assert_raises(Product::AlreadyRegistered) do
        2.times { register_product(uid, fake_name) }
      end
    end

    private

    def register_product(uid, name)
      run_command(RegisterProduct.new(product_uid: uid, name: name))
    end

    def fake_name
      'Fake name'
    end
  end
end

