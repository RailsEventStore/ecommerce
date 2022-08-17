require_relative 'test_helper'
module ProductCatalog
  class NamingTest < Test
    cover "ProductCatalog*"

    def test_should_publish_event
      uid = SecureRandom.uuid
      product_named = ProductCatalog::ProductNamed.new(data: {product_id: uid, name: fake_name})
      assert_events("Catalog::ProductName$#{uid}", product_named) do
        name_product(uid, fake_name)
      end
    end

    private

    def name_product(uid, name)
      run_command(NameProduct.new(product_id: uid, name: name))
    end

    def fake_name
      "Fake name"
    end
  end
end
