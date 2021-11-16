require_relative "../../ecommerce/configuration"
require_relative "customer_repository"

class Configuration
  def call(cqrs)
    enable_res_infra_event_linking(cqrs)

    enable_orders_read_model(cqrs)
    enable_products_read_model(cqrs)
    enable_customers_read_model(cqrs)

    Ecommerce::Configuration.new(
      number_generator: Rails.configuration.number_generator,
      payment_gateway: Rails.configuration.payment_gateway
    ).call(cqrs)
  end

  private

  def enable_res_infra_event_linking(cqrs)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| cqrs.subscribe_to_all_events(h) }
  end

  def enable_products_read_model(cqrs)
    Products::Configuration.new.call(cqrs)
  end

  def enable_customers_read_model(cqrs)
    Customers::Configuration.new.call(cqrs)
  end

  def enable_orders_read_model(cqrs)
    Orders::Configuration.new(customer_repository).call(cqrs)
  end

  def customer_repository
    @customer_repo ||= CustomerRepository.new
  end
end