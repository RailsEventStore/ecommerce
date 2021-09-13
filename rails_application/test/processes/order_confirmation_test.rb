require "test_helper"

class OrderConfirmationTest < Ecommerce::InMemoryTestCase

  cover "OrderConfirmation"

  def test_authorized_is_not_enough_to_confirm
    product_id = SecureRandom.uuid
    run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"))
    run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))
    customer_id = SecureRandom.uuid
    run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "test"))
    [
      Pricing::AddItemToBasket.new(order_id: order_id, product_id: product_id),
      Ordering::SubmitOrder.new(order_id: order_id, customer_id: customer_id),
      Payments::AuthorizePayment.new(order_id: order_id)
    ].each do |cmd|
      Rails.configuration.command_bus.call(cmd)
    end
    assert_equal("Submitted", Orders::Order.find_by_uid(order_id).state)
  end

  def test_payment_confirms_order
    product_id = SecureRandom.uuid
    run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"))
    run_command(Pricing::SetPrice.new(product_id: product_id, price: 39))

    customer_id = SecureRandom.uuid
    run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "test"))
    [
      Pricing::AddItemToBasket.new(order_id: order_id, product_id: product_id),
      Ordering::SubmitOrder.new(order_id: order_id, customer_id: customer_id),
      Payments::AuthorizePayment.new(order_id: order_id),
      Payments::CapturePayment.new(order_id: order_id)
    ].each do |cmd|
      Rails.configuration.command_bus.call(cmd)
    end
    assert_equal("Ready to ship (paid)", Orders::Order.find_by_uid(order_id).state)
  end

  def order_id
    @order_id ||= SecureRandom.uuid
  end

end
