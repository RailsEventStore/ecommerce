require "test_helper"

module Processes
  class ProductNameModerationTest < ProcessTest
    cover "Processes::ProductNameModeration*"

    def test_requests_moderation_when_name_change_requested
      given([name_change_requested], process:)

      assert_command(ProductCatalog::ModerateProductName)
    end

    def test_names_product_when_name_approved
      given([name_approved], process:)

      assert_command(ProductCatalog::NameProduct)
    end

    private

    def assert_command(command_class)
      assert_instance_of(command_class, command_bus.received)
      assert_equal(product_id, command_bus.received.product_id)
      assert_equal(product_name, command_bus.received.name)
    end

    def process
      ProductNameModeration.new(command_bus)
    end

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def product_name
      "Async Remote"
    end

    def name_change_requested
      ProductCatalog::ProductNameChangeRequested.new(
        data: { product_id: product_id, name: product_name }
      )
    end

    def name_approved
      ProductCatalog::ProductNameApproved.new(
        data: { product_id: product_id, name: product_name }
      )
    end
  end
end
