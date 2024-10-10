# Exercises

In the project there are integration tests available. During the exercises we're going to
refactor the system. Our goal is to keep tests green at each step. That way
we'll ensure that we're not breaking anything.

Before running tests make sure you're in the `rails_application` directory.
To run the integration tests use the following command:
`bin/rails t test/integration/`

To run all tests use `bin/rails t`.

## Disclaimer

There is no one and only correct solution to this exercise. However, to make it
easier to follow the instruction we suggest to stick with suggested naming of events,
event handlers etc.

## Exercise 1 - Most Recent Products In Unfinished Orders

### Problem

Business needs a new report. The report is there to help to
visualize which products are most often abandoned in the cart.

This is a long-term initiative. Business is aware that currently there
is no past data to get this information. However, they want to start.

### Solution proposition

We decided that we'll introduce events to gather information needed to
build the report.

##### Step 1 - publishing events

We'll start with publishing events necessary to build the report.
Think (and discuss, if you're doing this exercise in a group) about events
required to build the report.

Additionally, think about what Bounded Context the events should belong to.

Create new modules (there will be 2), based on your idea about Bounded Context, in `app/models`
and add necessary events there.

Events should inherit from `Infra::Event`. An example of an event:

```ruby

module Shipping
  class PackageShipped < Infra::Event
  end
end
```

<details>
  <summary>Hint</summary>

Minimal solution requires us to know:

- Existing products and their names. Therefore, we need to publish following events:
    - `ProductCreated`
    - `ProductNameChanged`
    - `OrderExpired`

`ProductCreated` and `ProductNameChanged` should belong to `ProductCatalog` module.
`OrderExpired` should belong to `Ordering` module.
</details>

<details>
<summary>Solution for step 1</summary>

Create following directories in `app/models`:
- product_catalog
- ordering

Add following events:

```ruby
# app/models/product_catalog/product_created.rb
module ProductCatalog
  class ProductCreated < Infra::Event
  end
end

# app/models/product_catalog/product_name_changed.rb
module ProductCatalog
  class ProductNameChanged < Infra::Event
  end
end

# app/models/ordering/order_expired.rb
module Ordering
  class OrderExpired < Infra::Event
  end
end
```
Those are all events we need for minimal solution.

In `ProductsController#create` method introduce following change:
```ruby
-    Product.create!(product_params)
+    ApplicationRecord.transaction do
+      product = Product.create!(product_params)
+      event_store.publish(ProductCatalog::ProductCreated.new(data: product_params.merge(id: product.id)), stream_name: "ProductCatalog::Product$#{product.id}")
+    end
```

In `ProductsController#update` method introduce following change:
```ruby
-    if params["future_price"].present?
-      @product.future_price = params["future_price"]["price"]
-      @product.future_price_start_time = params["future_price"]["start_time"]
-      @product.save!
+    ApplicationRecord.transaction do
+      if params["future_price"].present?
+        @product.future_price = params["future_price"]["price"]
+        @product.future_price_start_time = params["future_price"]["start_time"]
+        @product.save!
+      end
+      if !!product_params[:name] && @product.name != product_params[:name]
+        event_store.publish(ProductCatalog::ProductNameChanged.new(data: { id: @product.id, name: product_params[:name] }), stream_name: "ProductCatalog::Product$#{@product.id}"
)
+      elsif !!product_params[:price] && @product.price != product_params[:price]
+        event_store.publish(ProductCatalog::ProductPriceChanged.new(data: { id: @product.id, price: product_params[:price].to_d }), stream_name: "ProductCatalog::Product$#{@prod
uct.id}")
+      end
+      @product.update!(product_params)
     end
-    @product.update!(product_params)
```

**Question**: Why do we need to wrap product creation and modification and event publishing in a transaction?

</details>

##### Step 2 - building the report

The report will be built based on the events we've published in step 1.
Reports name should be `MostRecentProductsInUnfinishedOrders`.

The report will be created as simple Active Record model.

**Question**: What schema should the report have?

<details>
  <summary>Schema</summary>

```ruby
create_table :most_recent_products_in_unfinished_orders do |t|
  t.string :product_name, null: false
  t.integer :product_id, null: false, index: true
  t.integer :number_of_unfinished_orders, default: 0, null: false
  t.integer :number_of_items_in_unfinished_orders, default: 0, null: false
  t.integer :order_ids, array: true, default: [], null: false

  t.timestamps
end
```
</details>

Now we need to introduce a new event handler that will update the report based on the events.
We'll create the event handler in `read_models` directory and name it `BuildMostRecentProductsInUnfinishedOrders`.

<details>
  <summary>Order Expired Hint</summary>

You can handle `OrderExpired` event in the following way to get involved products and update the report:
```ruby
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
```
</details>

<details>
  <summary>Full solution</summary>

  ```ruby
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
  ```
</details>

##### Step 3 - does it work as expected?

Natural next step is to prepare test. What do you think the arrange/setup/given part of the test should look like?

<details>
  <summary>Test implementation</summary>

```ruby
class BuildMostRecentProductsInUnfinishedOrdersTest < InMemoryTestCase
  def test_build
    product_1_id = 1
    product_2_id = 2
    product_3_id = 3
    event_store.publish(ProductCatalog::ProductCreated.new(data: { id: product_1_id, name: 'Product 1' }), stream_name: 'ProductCatalog::Product$1')
    event_store.publish(ProductCatalog::ProductCreated.new(data: { id: product_2_id, name: 'Product 2' }), stream_name: 'ProductCatalog::Product$2')
    event_store.publish(ProductCatalog::ProductCreated.new(data: { id: product_3_id, name: 'Product 3' }), stream_name: 'ProductCatalog::Product$3')

    order_1_id = 1
    order_2_id = 2

    event_store.publish(Ordering::OrderCreated.new(data: { id: order_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_1_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_1_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_1_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::OrderSubmitted.new(data: { id: order_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::OrderExpired.new(data: { id: order_1_id }), stream_name: "Ordering::Order$#{order_1_id}")

    event_store.publish(Ordering::OrderCreated.new(data: { id: order_2_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_2_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::OrderPaid.new(data: { id: order_2_id }), stream_name: "Ordering::Order$#{order_2_id}")


    MostRecentProductsInUnfinishedOrders.find_by(product_id: product_1_id).tap do |report|
      assert_equal 1, report.number_of_unfinished_orders
      assert_equal 3, report.number_of_items_in_unfinished_orders
      assert_equal [order_1_id], report.order_ids
    end
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
```
</details>
