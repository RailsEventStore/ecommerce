module Shipments
  class Shipment < ApplicationRecord
    self.table_name = "shipments"

    has_one :order,
      class_name: "Orders::Order",
      foreign_key: :uid,
      primary_key: :order_uid

    has_many :shipment_items

    scope :with_full_address, -> { where.not(address_line_1: nil, address_line_2: nil, address_line_3: nil, address_line_4: nil) }

    def full_address
      [address_line_1, address_line_2, address_line_3, address_line_4].join(" ")
    end
  end

  class Order < ApplicationRecord
    self.table_name = "shipments_orders"
  end

  class ShipmentItem < ApplicationRecord
    self.table_name = "shipment_items"

    belongs_to :shipment
  end

  def self.shipments_for_store(store_id)
    Shipment
      .joins(:order)
      .where(orders: { store_id: store_id })
  end

  def self.find_shipment_in_store(id, store_id)
    Shipment.where(store_id: store_id).find_by_id(id)
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(SetShippingAddress, to: [Shipping::ShippingAddressAddedToShipment])
      event_store.subscribe(MarkOrderPlaced, to: [Fulfillment::OrderRegistered])
      event_store.subscribe(AddItemToShipment, to: [Shipping::ItemAddedToShipmentPickingList])
      event_store.subscribe(RemoveItemFromShipment, to: [Shipping::ItemRemovedFromShipmentPickingList])
      event_store.subscribe(AssignStoreToShipment, to: [Stores::ShipmentRegistered])
    end
  end
end
