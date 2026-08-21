require_relative 'test_helper'

module ProductCatalog
  class ModerationTest < Test
    cover "ProductCatalog*"

    def test_requesting_name_change_publishes_event
      uid = SecureRandom.uuid
      name_change_requested = ProductNameChangeRequested.new(data: { product_id: uid, name: allowed_name })
      assert_events("Catalog::ProductName$#{uid}", name_change_requested) do
        run_command(RequestProductNameChange.new(product_id: uid, name: allowed_name))
      end
    end

    def test_approves_name_allowed_by_moderation
      uid = SecureRandom.uuid
      name_approved = ProductNameApproved.new(data: { product_id: uid, name: allowed_name })
      assert_events("Catalog::ProductName$#{uid}", name_approved) do
        run_command(ModerateProductName.new(product_id: uid, name: allowed_name))
      end
    end

    def test_rejects_name_not_allowed_by_moderation
      uid = SecureRandom.uuid
      name_rejected = ProductNameRejected.new(data: { product_id: uid, name: rejected_name })
      assert_events("Catalog::ProductName$#{uid}", name_rejected) do
        run_command(ModerateProductName.new(product_id: uid, name: rejected_name))
      end
    end

    def test_moderation_command_is_not_registered_without_name_moderation
      command_bus = Infra::CommandBus.new
      Configuration.new.call(event_store, command_bus)

      assert_raises(Arkency::CommandBus::UnregisteredHandler) do
        command_bus.call(ModerateProductName.new(product_id: SecureRandom.uuid, name: allowed_name))
      end
    end

    private

    def allowed_name
      "Fake name"
    end

    def rejected_name
      "Curse word"
    end
  end
end
