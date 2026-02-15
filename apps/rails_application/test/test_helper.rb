ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mutant/minitest/coverage"

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

class ProcessTest < Minitest::Test
  include Infra::TestPlumbing.with(
    event_store: -> { Infra::EventStore.in_memory },
    command_bus: -> { FakeCommandBus.new }
  )

  def assert_command(command)
    assert_equal(command, @command_bus.received)
  end

  def assert_all_commands(*commands)
    assert_equal(commands, @command_bus.all_received)
  end

  def assert_no_command
    assert_nil(@command_bus.received)
  end

  private

  class FakeCommandBus
    attr_reader :received, :all_received

    def initialize
      @all_received = []
    end

    def call(command)
      @received = command
      @all_received << command
    end

    def clear_all_received
      @all_received, @received = [], nil
    end
  end

  def order_id
    @order_id ||= SecureRandom.uuid
  end

  def order_number
    "2018/12/16"
  end

  def customer_id
    @customer_id ||= SecureRandom.uuid
  end

  def given(events, store: event_store, process: nil)
    events.flatten.each do |ev|
      store.append(ev)
      process.call(ev) if process
    end
  end

  def order_placed
    Fulfillment::OrderRegistered.new(
      data: {
        order_id: order_id,
        order_number: order_number,
      }
    )
  end

  def order_expired
    Pricing::OfferExpired.new(data: { order_id: order_id })
  end

  def order_confirmed
    Fulfillment::OrderConfirmed.new(data: { order_id: order_id })
  end

  def order_cancelled
    Fulfillment::OrderCancelled.new(data: { order_id: order_id })
  end

  def payment_authorized
    Payments::PaymentAuthorized.new(data: { order_id: order_id })
  end

  def payment_captured
    Payments::PaymentCaptured.new(data: { order_id: order_id })
  end

  def payment_released
    Payments::PaymentReleased.new(data: { order_id: order_id })
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

  def register_customer(name="Test Customer")
    customer_id = SecureRandom.uuid
    post "/customers", params: { customer_id: customer_id, name: name }
    customer_id
  end

  def register_product(name, price, vat_rate_code)
    product_id = SecureRandom.uuid
    post "/products", params: { product_id: product_id, name: name, price: price, vat_rate_code: vat_rate_code }
    product_id
  end

  def register_coupon(name, code, discount)
    post "/coupons", params: { coupon_id: SecureRandom.uuid, name: name, code: code, discount: discount }
  end

  def add_available_vat_rate(rate, code = rate.to_s)
    post "/available_vat_rates", params: { code: code, rate: rate }
    assert_response :redirect
  end

  def supply_product(product_id, quantity)
    post "/products/#{product_id}/supplies", params: { quantity: quantity }
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

  def add_item_to_return(order_id, return_id, product_id)
    post "/orders/#{order_id}/returns/#{return_id}/add_item?product_id=#{product_id}"
  end

  def remove_item_from_return(order_id, return_id, product_id)
    post "/orders/#{order_id}/returns/#{return_id}/remove_item?product_id=#{product_id}"
  end

  def create_order
    get "/orders/new"
    follow_redirect!
    request.path.split("/")[2]
  end

  def create_client_order
    get "/client_orders/new"
    follow_redirect!
    request.path.split("/")[2]
  end

  def run_command(command)
    Rails.configuration.command_bus.call(command)
  end

  def register_store(name)
    store_id = SecureRandom.uuid
    post "/admin/stores", params: { store_id: store_id, name: name }
    store_id
  end
end
