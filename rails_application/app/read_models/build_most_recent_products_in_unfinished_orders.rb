# frozen_string_literal: true

class BuildMostRecentProductsInUnfinishedOrders
  def call(event)
    case event
    when ProductCatalog::ProductCreated
      handle_product_created(event)
    when ProductCatalog::ProductNameChanged
      handle_product_name_changed(event)
    when Ordering::OrderExpired
      handle_order_expired(event)
    end
  end

  private

  def handle_product_created(event)
    product_id = event.data[:id]
    product_name = event.data[:name]

    MostRecentProductsInUnfinishedOrders.create!(product_id: product_id, product_name: product_name)
  end

  def handle_product_name_changed(event)
    product_id = event.data[:id]
    new_name = event.data[:name]

    MostRecentProductsInUnfinishedOrders.find_by(product_id: product_id)&.update!(product_name: new_name)
  end

  def handle_order_expired(event)
    order_id = event.data[:id]

    product_ids = {}

    event_store.read.stream("Ordering::Order$#{order_id}").each do |event|
      case event
      when Ordering::ItemAdded
        product_ids.include?(event.data[:product_id]) ? product_ids[event.data[:product_id]] += 1 : product_ids[event.data[:product_id]] = 1
      when Ordering::ItemRemoved
        product_ids.include?(event.data[:product_id]) ? product_ids[event.data[:product_id]] -= 1 : product_ids.delete(event.data[:product_id])
      end
    end

    product_ids.each do |product_id, quantity|
      report = MostRecentProductsInUnfinishedOrders.find_by(product_id: product_id)
      report.number_of_unfinished_orders += 1
      report.number_of_items_in_unfinished_orders += quantity
      report.order_ids << order_id
      report.save!
    end
  end

  def event_store
    Rails.configuration.event_store
  end
end
