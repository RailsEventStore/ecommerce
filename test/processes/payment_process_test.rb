require 'test_helper'

class PaymentProcessTest < ActiveSupport::TestCase
  test 'happy path' do
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given([
      order_submitted,
      payment_authorized,
      order_paid
    ]).each do |event|
      process.call(event)
    end
    assert_nil(fake.received)
  end

  test 'order expired without payment' do
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given([
      order_submitted,
      order_expired,
    ]).each do |event|
      process.call(event)
    end
    assert_nil(fake.received)
  end

  test 'order expired after payment authorization' do
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given([
      order_submitted,
      payment_authorized,
      order_expired,
    ]).each do |event|
      process.call(event)
    end
    assert_equal(fake.received,
      Payments::ReleasePayment.new(transaction_id: transaction_id)
    )
  end

  test 'order expired after payment released' do
    fake = FakeCommandBus.new
    process = PaymentProcess.new(bus: fake)
    given([
      order_submitted,
      payment_authorized,
      payment_released,
      order_expired,
    ]).each do |event|
      process.call(event)
    end
    assert_nil(fake.received)
  end

  private

  class FakeCommandBus
    attr_reader :received
    def call(command)
      @received = command
    end
  end

  def transaction_id
    @transaction_id ||= SecureRandom.hex(16)
  end

  def order_id
    @order_id ||= SecureRandom.uuid
  end

  def order_number
    '2018/12/16'
  end

  def customer_id
    123
  end

  def given(events, store: Rails.configuration.event_store)
    events.each{|ev| store.append(ev)}
    events
  end

  def order_submitted
    Ordering::OrderSubmitted.new(data: {order_id: order_id, order_number: order_number, customer_id: customer_id})
  end

  def order_expired
    Ordering::OrderExpired.new(data: {order_id: order_id})
  end

  def order_paid
    Ordering::OrderPaid.new(data: {order_id: order_id, transaction_id: transaction_id})
  end

  def payment_authorized
    Payments::PaymentAuthorized.new(data: {
      transaction_id: transaction_id,
      order_id: order_id
    })
  end

  def payment_released
    Payments::PaymentReleased.new(data: {
      transaction_id: transaction_id,
      order_id: order_id
    })
  end
end
