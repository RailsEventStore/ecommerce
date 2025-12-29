require_relative "../../../ecommerce/configuration"
require_relative "../../../infra/lib/infra"

class Configuration
  def call(event_store, command_bus)
    enable_res_infra_event_linking(event_store)

    enable_orders_read_model(event_store)
    enable_order_header_read_model(event_store)
    enable_products_read_model(event_store)
    enable_public_offer_products_read_model(event_store)
    enable_customers_read_model(event_store)
    enable_invoices_read_model(event_store)
    enable_client_orders_read_model(event_store)
    enable_client_inbox_read_model(event_store)
    enable_coupons_read_model(event_store)
    enable_time_promotions_read_model(event_store)
    enable_shipments_read_model(event_store)
    enable_availability_read_model(event_store)
    enable_authentication_read_model(event_store)
    enable_vat_rates_read_model(event_store)
    enable_returns_read_model(event_store)
    enable_admin_read_model(event_store)
    configure_processes(event_store, command_bus)

    Ecommerce::Configuration.new(
      number_generator: Rails.configuration.number_generator,
      payment_gateway: Rails.configuration.payment_gateway
    ).call(event_store, command_bus)
  end

  private

  def enable_res_infra_event_linking(event_store)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| event_store.subscribe_to_all_events(h) }
  end

  def enable_products_read_model(event_store)
    Products::Configuration.new(event_store).call
  end

  def enable_public_offer_products_read_model(event_store)
    PublicOffer::Configuration.new(event_store).call
  end

  def enable_customers_read_model(event_store)
    Customers::Configuration.new.call(event_store)
  end

  def enable_orders_read_model(event_store)
    Orders::Configuration.new.call(event_store)
  end

  def enable_order_header_read_model(event_store)
    OrderHeader::Configuration.new.call(event_store)
  end

  def enable_invoices_read_model(event_store)
    Invoices::Configuration.new.call(event_store)
  end

  def enable_client_orders_read_model(event_store)
    ClientOrders::Configuration.new.call(event_store)
  end

  def enable_client_inbox_read_model(event_store)
    ClientInbox::Configuration.new.call(event_store)
  end

  def enable_coupons_read_model(event_store)
    Coupons::Configuration.new.call(event_store)
  end

  def enable_time_promotions_read_model(event_store)
    TimePromotions::Configuration.new.call(event_store)
  end

  def enable_shipments_read_model(event_store)
    Shipments::Configuration.new.call(event_store)
  end

  def enable_availability_read_model(event_store)
    Availability::Configuration.new.call(event_store)
  end

  def enable_authentication_read_model(event_store)
    ClientAuthentication::Configuration.new.call(event_store)
  end

  def enable_vat_rates_read_model(event_store)
    VatRates::Configuration.new.call(event_store)
  end

  def enable_returns_read_model(event_store)
    Returns::Configuration.new.call(event_store)
  end

  def enable_admin_read_model(event_store)
    Admin::Configuration.new.call(event_store)
  end

  def configure_processes(event_store, command_bus)
    Processes::Configuration.new.call(event_store, command_bus)
  end
end
