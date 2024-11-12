require_relative '../test_helper'

class SavingIssuesWhenTwoAdminsWorkOnSameProductTest < RealRESIntegrationTestCase
  def before_setup
    post "/customers", params: { customer: { first_name: "Arkency", last_name: "Arkency", email: "lukasz@arkency.com" } }
    post "/products", params: { product: { name: 'book', price: 10.00, vat_rate: 10, sku: "B00K" } }
    super
  end

  def test_two_admins_cannot_work_on_same_product_stable
    admin_works_on_product_details = the_product
    admin_works_on_product_stock = the_product
    # When first admin updates quantity
    post "/products/#{admin_works_on_product_stock.id}/supplies", params: { quantity: 10 }
    # When second admin updates name
    patch "/products/#{admin_works_on_product_details.id}", params: { product: { name: 'bUk', version: admin_works_on_product_details.version } }
    # Then the second admins change is not saved and they lose time
    refute response.status == 409
  end

  def test_when_admins_works_on_product_they_are_blocked_by_customers_ordering
    product = the_product
    supply_product(product)
    order = Order.create!(total: 0)
    order_id = order.id
    product_id = product.id
    initial_version = product.version
    latch = Concurrent::CountDownLatch.new
    admin_result = nil

    thread1 = Thread.new do
      latch.wait
      post "/orders/#{order_id}/add_item?product_id=#{product_id}"
    end

    thread2 = Thread.new do
      latch.wait
      patch "/products/#{product.id}", params: { product: { name: 'bUk', version: initial_version } }
      admin_result = response.status
    end

    thread3 = Thread.new do
      latch.wait
      post "/orders/#{order_id}/add_item?product_id=#{product_id}"
    end

    threads = [thread1, thread2, thread3]
    threads << Thread.new do
      latch.count_down
    end
    threads.each(&:join)

    refute admin_result == 409
  end

  private

  def supply_product(product)
    post "/products/#{product.id}/supplies", params: { quantity: 10 }
  end

  def the_product
    Product.last
  end
end