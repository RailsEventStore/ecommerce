module Returns
  class Return < ApplicationRecord
    self.table_name = "returns"

    has_many :return_items,
             class_name: "Returns::ReturnItem",
             foreign_key: :return_uid,
             primary_key: :uid
  end

  class ReturnItem < ApplicationRecord
    self.table_name = "return_items"

    attr_accessor :order_line
    delegate :product_name, to: :order_line

    def max_quantity?
      quantity == order_quantity
    end

    def order_quantity
      order_line.quantity
    end

    def value
      quantity * price
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateDraftReturn.new, to: [Ordering::DraftReturnCreated])
      event_store.subscribe(AddItemToReturn.new, to: [Ordering::ItemAddedToReturn])
      event_store.subscribe(RemoveItemFromReturn.new, to: [Ordering::ItemRemovedFromReturn])
      event_store.subscribe(SetOrderNumber.new, to: [Fulfillment::OrderRegistered])
    end
  end

  # Backward compatibility aliases
  Refund = Return
  RefundItem = ReturnItem
end
