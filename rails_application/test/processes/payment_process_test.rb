require "test_helper"

class PaymentProcessTest < Ecommerce::InMemoryTestCase
  cover "PaymentProcess*"

  def test_happy_path
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given([order_submitted, payment_authorized, order_paid]).each do |event|
      process.call(event)
    end
    assert_nil(fake.received)
  end

  def test_order_expired_without_payment
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given([order_submitted, order_expired]).each { |event| process.call(event) }
    assert_nil(fake.received)
  end

  def test_order_expired_after_payment_authorization
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given([order_submitted, payment_authorized, order_expired]).each do |event|
      process.call(event)
    end
    assert_equal(
      fake.received,
      Payments::ReleasePayment.new(order_id: order_id)
    )
  end

  def test_order_expired_after_payment_released
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given(
      [order_submitted, payment_authorized, payment_released, order_expired]
    ).each { |event| process.call(event) }
    assert_nil(fake.received)
  end

  private

  class FakeCommandBus
    attr_reader :received
    def call(command)
      @received = command
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

  def given(events, store: Rails.configuration.event_store)
    events.each { |ev| store.append(ev) }
    events
  end

  def order_submitted
    Ordering::OrderSubmitted.new(
      data: {
        order_id: order_id,
        order_number: order_number,
        customer_id: customer_id
      }
    )
  end

  def order_expired
    Ordering::OrderExpired.new(data: { order_id: order_id })
  end

  def order_paid
    Ordering::OrderPaid.new(data: { order_id: order_id })
  end

  def payment_authorized
    Payments::PaymentAuthorized.new(data: { order_id: order_id })
  end

  def payment_released
    Payments::PaymentReleased.new(data: { order_id: order_id })
  end
end
