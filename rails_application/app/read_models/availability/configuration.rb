module Availability
  class Product < ApplicationRecord
    self.table_name = "availability_products"
  end

  class UpdateAvailability < Infra::EventHandler
    def call(event)
      order = Product.find_or_create_by!(uid: event.data.fetch(:product_id))
      order.available = event.data.fetch(:available)
      order.save!
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(UpdateAvailability, to: [Inventory::AvailabilityChanged])
    end
  end
end