require_relative 'test_helper'

module ProductCatalog
  class ArchivizationTest < Test
    cover "ProductCatalog*"

    def test_product_should_get_archived
      uid = SecureRandom.uuid
      assert archive_product(uid)
    end

    def test_should_publish_event
      uid = SecureRandom.uuid
      product_archived = ProductCatalog::ProductArchived.new(data: { product_id: uid })
      assert_events("ProductCatalog$#{uid}", product_archived) do
        archive_product(uid)
      end
    end

    private

    def archive_product(uid)
      run_command(ArchiveProduct.new(product_id: uid))
    end
  end
end