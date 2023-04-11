ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mutant/minitest/coverage"
require "sidekiq/testing"

ActiveJob::Base.logger = Logger.new(nil)

class InMemoryTestCase < ActiveSupport::TestCase
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
  def run_command(command)
    Rails.configuration.command_bus.call(command)
  end
end

class InMemoryRESIntegrationTestCase < ActionDispatch::IntegrationTest
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

  def register_customer(name)
    customer_id = SecureRandom.uuid
    post "/customers", params: { customer_id: customer_id, name: name }
    customer_id
  end

  def register_product(name, price, vat_rate)
    product_id = SecureRandom.uuid
    post "/products", params: { product_id: product_id, name: name, price: price, vat_rate: vat_rate }
    product_id
  end

  def update_price(product_id, new_price)
    patch "/products/#{product_id}",
          params: {
            "authenticity_token" => "[FILTERED]",
            "product_id" => product_id,
            price: new_price,
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

  def pay_order(order_id)
    post "/orders/#{order_id}/pay"
  end

  def visit_client_orders
    get "/client_orders"
  end

  def add_product_to_basket(order_id, product_id)
    post "/orders/#{order_id}/add_item?product_id=#{product_id}"
  end

  def run_command(command)
    puts "Command: #{command.class} used in integrations test."
    Rails.configuration.command_bus.call(command)
  end
end
