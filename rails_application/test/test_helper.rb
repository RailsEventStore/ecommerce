ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mutant/minitest/coverage"
require "sidekiq/testing"

ActiveJob::Base.logger = Logger.new(nil)

class InMemoryTestCase < ActiveSupport::TestCase

  def setup
    super
    Sidekiq.logger.level = Logger::WARN
  end

  def before_setup
    result = super
    @previous_event_store = Rails.configuration.event_store
    @previous_command_bus = Rails.configuration.command_bus
    Rails.configuration.event_store = Infra::EventStore.in_memory
    Rails.configuration.command_bus = Arkency::CommandBus.new

    Configuration.new.call(
      Rails.configuration.event_store, Rails.configuration.command_bus
    )
    result
  end

  def before_teardown
    result = super
    Rails.configuration.event_store = @previous_event_store
    Rails.configuration.command_bus = @previous_command_bus
    result
  end

  def run_command(command)
    Rails.configuration.command_bus.call(command)
  end
end

class RealRESIntegrationTestCase < ActionDispatch::IntegrationTest
  def setup
    super
    Sidekiq.logger.level = Logger::WARN
  end

  def run_command(command)
    Rails.configuration.command_bus.call(command)
  end
end

class InMemoryRESIntegrationTestCase < ActionDispatch::IntegrationTest
  include Infra::TestPlumbing.with(
    event_store: -> { Infra::EventStore.in_memory_rails },
    command_bus: -> { Arkency::CommandBus.new }
  )


  def setup
    super
    Sidekiq.logger.level = Logger::WARN
  end

  def before_setup
    result = super
    @previous_event_store = Rails.configuration.event_store
    @previous_command_bus = Rails.configuration.command_bus
    Rails.configuration.event_store = Infra::EventStore.in_memory_rails
    Rails.configuration.command_bus = Arkency::CommandBus.new

    Configuration.new.call(Rails.configuration.event_store, Rails.configuration.command_bus)
    result
  end

  def before_teardown
    result = super
    Rails.configuration.event_store = @previous_event_store
    Rails.configuration.command_bus = @previous_command_bus
    result
  end

  def register_customer(name, email = "user@example.com")
    post "/customers", params: { customer: { first_name: name, last_name: "", email: } }
    Customer.find_by(email:).id
  end

  def register_product(name, price, vat_rate, sku = SecureRandom.uuid, stock_level: 10)
    post "/products", params: { product: { name: name, price: price, vat_rate: vat_rate, sku: } }
    product = Product.find_by(sku:)
    post "/products/#{product.id}/supplies", params: { product_id: product.id, quantity: stock_level }
    product.id
  end

  def supply_product(product_id, quantity)
    post "/products/#{product_id}/supplies", params: { quantity: quantity }
  end

  def update_price(product_id, new_price)
    patch "/products/#{product_id}",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            product: { price: new_price },
          }
  end

  def login(client_id)
    post "/login", params: { client_id: client_id }
    follow_redirect!
  end

  def submit_order(customer_id, order_id)
    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => customer_id,
           "commit" => "Submit order"
           }
  end

  def visit_customers_index
    get "/customers"
  end

  def visit_customer_page(customer_id)
    get "/customers/#{customer_id}"
  end

  def pay_order(order_id)
    post "/orders/#{order_id}/pay"
  end

  def visit_client_orders
    get "/client_orders"
  end

  def add_product_to_basket(order_id, product_id)
    post "/orders/#{order_id}/add_item?product_id=#{product_id}"
  end

  def new_order
    get "/orders/new"
    Order.last
  end

  def run_command(command)
    Rails.configuration.command_bus.call(command)
  end
end
