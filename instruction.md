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

### Step 1 - publishing events

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
-Product.create!(product_params)
+ApplicationRecord.transaction do
  +product = Product.create!(product_params)
  +event_store.publish(ProductCatalog::ProductCreated.new(data: product_params.merge(id: product.id)), stream_name: "ProductCatalog::Product$#{product.id}")
  +
end
```

In `ProductsController#update` method introduce following change:

```ruby
-if params["future_price"].present?
   -@product.future_price = params["future_price"]["price"]
   -@product.future_price_start_time = params["future_price"]["start_time"]
   -@product.save!
   +ApplicationRecord.transaction do
     +if params["future_price"].present?
        +@product.future_price = params["future_price"]["price"]
        +@product.future_price_start_time = params["future_price"]["start_time"]
        +@product.save!
        +
      end
     +if !!product_params[:name] && @product.name != product_params[:name]
        +event_store.publish(ProductCatalog::ProductNameChanged.new(data: { id: @product.id, name: product_params[:name] }), stream_name: "ProductCatalog::Product$#{@product.id}"
        )
        +
      elsif !!product_params[:price] && @product.price != product_params[:price]
        +event_store.publish(ProductCatalog::ProductPriceChanged.new(data: { id: @product.id, price: product_params[:price].to_d }), stream_name: "ProductCatalog::Product$#{@prod
        uct.id}")
        +
      end
     +@product.update!(product_params)
   end
   -@product.update!(product_params)
```

**Question**: Why do we need to wrap product creation and modification and event publishing in a transaction?

</details>

### Step 2 - building the report

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

### Step 3 - does it work as expected?

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

## Exercise 2 - Decoupling Product from Stock Level

### Problem

### Solution

### Solution proposition

### Step 1 - introducing aggregate

The goal of the aggregate is to take care of the stock level.
But... stock level of what? All products? Or maybe only some of them?
Your first goal is to answer that question.

<details>
  <summary>Answer</summary>

Aggregate should take care of stock level of a single product.

Create aggregate in the `app/models/inventory` directory. Name it `Product`.
</details>

Now it is time to write a test. What is the observable behaviour that should be tested?

Events! We want to see that events are published.

<details>
  <summary>Hint - events and methods names</summary>

We suggest to start with following events:

- `StockLevelIncreased`
- `StockLevelDecreased`
  and following method names:
- `supply`
- `withdraw`

</details>

<details>
  <summary>Test implementation</summary>

```ruby
# frozen_string_literal: true

require 'test_helper'

module Inventory
  class ProductTest < Infra::InMemoryTest
    def test_supply
      product_id = 1024

      assert_events(stream_name(product_id), StockLevelIncreased.new(data: { id: product_id, quantity: 10 })) do
        with_aggregate(product_id) do |product|
          product.supply(10)
        end
      end
    end

    def test_withdraw
      product_id = 1024

      assert_events(stream_name(product_id),
                    StockLevelIncreased.new(data: { id: product_id, quantity: 10 }),
                    StockLevelDecreased.new(data: { id: product_id, quantity: 5 })
      ) do
        with_aggregate(product_id) do |product|
          product.supply(10)
          product.withdraw(5)
        end
      end
    end

    def test_withdraw_when_not_enough_stock_is_not_allowed
      product_id = 1024

      assert_nothing_published_within do
        assert_raises("Not enough stock") do
          with_aggregate(product_id) do |product|
            product.withdraw(10)
          end
        end
      end
    end

    private

    def stream_name(product_id)
      "Inventory::Product$#{product_id}"
    end

    def with_aggregate(product_id)
      Infra::AggregateRootRepository.new(event_store).with_aggregate(Product, product_id) do |product|
        yield product
      end
    end
  end
end
```

</details>

<details>
<summary>Aggregate Implementation</summary>

```ruby
# frozen_string_literal: true

module Inventory
  class Product
    include AggregateRoot

    private attr_reader :id

    def initialize(id)
      @id = id
      @stock_level = 0
    end

    def supply(quantity)
      apply(StockLevelIncreased.new(data: { id:, quantity: }))
    end

    def withdraw(quantity)
      raise "Not enough stock" if @stock_level < quantity
      apply(StockLevelDecreased.new(data: { id:, quantity: }))
    end

    on StockLevelIncreased do |event|
      @stock_level += event.data[:quantity]
    end

    on StockLevelDecreased do |event|
      @stock_level -= event.data[:quantity]
    end
  end
end

```

</details>

### Step 2 - preparing for refactoring

In a green field project we could just change the model and live happily after.

Yea.

But we're not in a green field project. Well. Most likely.

That's why we need to do a migration at some point. We'll do it and we'll do it safely. But first
we need to prepare for it. As a first step we will create a Facade that will take care of increasing and decreasing
stock level.

For simplicity we suggest naming it `ProductService`. It belongs to the `Inventory` module.
It should have `increase_stock_level`, `decrease_stock_level` and `supply` methods.

What do you think should be the implementation of those methods?

<details>
  <summary>Solution</summary>
Grep `product.decrement`, `product.increment` and `product.stock_level` in the codebase.
Replace them with the call to corresponding methods in the `ProductService`.
</details>

### Step 3 - start using new aggregate

Now it is time to start using the new aggregate. We'll use it through the `ProductService` facade.
But can we just start using it?

What about the existing data? We need to migrate it.

We'll start by introducing migration method and migration event into the aggregate.

Add following code to the `Inventory::Product` class:

```ruby

def migration_event(quantity)
  apply(StockLevelMigrated.new(data: { id:, quantity: }))
end

on StockLevelMigrated do |event|
  @stock_level = event.data[:quantity]
end
```

How to ensure that each record will be migrated? Migration script is one of the options.

How to ensure that the migration event is the first event in the stream? Can you take system down for migration?

If you can - it is a good option. But if you can't, what can you do? How to ensure that?

<details>
  <summary>Solution</summary>

We can add a little bit of logic to the `ProductService` to ensure that the migration event is the first event in the
stream.

```ruby
  +

def initialize
  +@repository = Infra::AggregateRootRepository.new(event_store)
  +
end
+

def decrement_stock_level(product_id)
  -product = ::Product.find(product_id)
  -product.decrement!(:stock_level)
  +ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product_id}") do
    +product = ::Product.find(product_id)
    +product_stream = event_store.read.stream("Inventory::Product$#{product_id}").to_a
    +
    +if product_stream.any? { |event| event.event_type == "Inventory::StockLevelMigrated" }
       +with_inventory_product(product_id) do |aggregate|
         +aggregate.withdraw(1)
         +
       end
       +
     else
       +with_inventory_product(product_id) do |aggregate|
         +aggregate.migration_event(product.stock_level)
         +aggregate.withdraw(1)
         +
       end
       +
     end
    +product.decrement!(:stock_level)
    +
  end
end

def increment_stock_level(product_id)
  -product = ::Product.find(product_id)
  -product.increment!(:stock_level)
  +ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product_id}") do
    +product = ::Product.find(product_id)
    +product_stream = event_store.read.stream("Inventory::Product$#{product_id}").to_a
    +
    +if product_stream.any? { |event| event.event_type == "Inventory::StockLevelMigrated" }
       +with_inventory_product(product_id) do |aggregate|
         +aggregate.supply(1)
         +
       end
       +
     else
       +with_inventory_product(product_id) do |aggregate|
         +aggregate.migration_event(product.stock_level)
         +aggregate.supply(1)
         +
       end
       +
     end
    +product.increment!(:stock_level)
    +
  end
end

def supply(product_id, quantity)
  -product = ::Product.find(product_id)
  -product.stock_level == nil ? product.stock_level = quantity : product.stock_level += quantity
  -product.save!
  +ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product_id}") do
    +product = ::Product.find(product_id)
    +product.stock_level == nil ? product.stock_level = quantity : product.stock_level += quantity
    +product_stream = event_store.read.stream("Inventory::Product$#{product_id}").to_a
    +
    +if product_stream.any? { |event| event.event_type == "Inventory::StockLevelMigrated" }
       +with_inventory_product(product_id) do |aggregate|
         +aggregate.supply(quantity)
         +
       end
       +
     else
       +with_inventory_product(product_id) do |aggregate|
         +aggregate.migration_event(product.stock_level)
         +
       end
       +
     end
    +product.save!
    +
  end
  +
end

+
+private
+
+

def event_store
  +Rails.configuration.event_store
  +
end
+
+

def with_inventory_product(product_id)
  +@repository.with_aggregate(Inventory::Product, product_id) do |product|
    +yield(product)
    +
  end
  +
end
```

</details>

### Step 4 - migration script

Now it is time to write a migration script.
Migration script should iterate over all products and initialize the `Inventory::Product` aggregate for each of them.

But... **test things first**

Write a test with expectations for your migration script.

<details>
<summary>The test</summary>

```ruby
require "test_helper"
require_relative "../../script/start_lifecycle_of_product_inventory_aggregate"

class MigrationTest < InMemoryRESIntegrationTestCase
  def setup
    super
  end

  def test_migration_applies_only_to_prodcuts_that_dont_have_migration_event_in_stream
    product_1_sku = "SKU-ST4NL3Y-1"
    product_2_sku = "SKU-ST4NL3Y-2"
    create_product(sku: product_1_sku)
    create_product(sku: product_2_sku)
    product_1_id = Product.find_by(sku: product_1_sku).id
    product_2_id = Product.find_by(sku: product_2_sku).id

    increase_stock_level_by_10(product_1_id)
    product_1_stream = event_store.read.stream("Inventory::Product$#{product_1_id}").to_a
    assert product_1_stream.map(&:event_type) == ["Inventory::StockLevelMigrated"]
    product_2_stream = event_store.read.stream("Inventory::Product$#{product_2_id}").to_a
    assert product_2_stream.empty?

    start_lifecycle_of_product_inventory_aggregate
    product_2_stream = event_store.read.stream("Inventory::Product$#{product_2_id}").to_a
    assert product_2_stream.map(&:event_type) == ["Inventory::StockLevelMigrated"]
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def increase_stock_level_by_10(product_id)
    post "/products/#{product_id}/supplies", params: { product_id: product_id, quantity: 10 }
  end

  def create_product(sku:)
    post "/products", params: { product: { name: "Stanley Cup", price: 100, vat_rate: 23, sku: } }
  end

  def sku
    "SKU-ST4NL3Y"
  end
end

```

</details>

Now you can safely write the migration script.

<details>
  <summary>Migration script</summary>

```ruby
# frozen_string_literal: true

def start_lifecycle_of_product_inventory_aggregate
  event_store = Rails.configuration.event_store
  repository = Infra::AggregateRootRepository.new(event_store)

  p 'Starting lifecycle of product inventory aggregate'

  ::Product.find_each do |product|
    ApplicationRecord.with_advisory_lock("change_stock_level_for_#{product.id}") do
      product_stream = event_store
        .read
        .stream("Inventory::Product$#{product.id}")
        .of_type("Inventory::StockLevelMigrated")
        .to_a

      p "Skipping product: #{product.id}"

      next if product_stream.any?

      repository.with_aggregate(Inventory::Product, product.id) do |aggregate|
        aggregate.migration_event(product.stock_level)
      end

      p "Migrated product: #{product.id}"

    end
  end

  p "Done"
end

start_lifecycle_of_product_inventory_aggregate
```

</details>

And now, perform the migration.

After the migration clean up the code. We don't need the facade to take care
of the migration event anymore.

### Step 5 - building read model on top of events

Introduce `UpdateProductStockLevel` event handler that will update the stock level of the product.

Events not handled by the event handler? Remember to subscribe event handler to events in `lib/configuration.rb`

```ruby
  event_store.subscribe(
  UpdateProductStockLevel,
  to: [Inventory::StockLevelIncreased, Inventory::StockLevelDecreased]
)
```

Do you pass the test?

```ruby
require 'test_helper'

class UpdateProductStockLevelTest < InMemoryTestCase
  def test_happy_path
    product = Product.create!(name: 'Test Product', price: 10, vat_rate: 23, sku: 'test', stock_level: 0)

    stock_level_increased = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    stock_level_increased_second_time = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
    event_store.append(stock_level_increased, stream_name: "Inventory::Product$#{product.id}")
    event_store.append(stock_level_increased_second_time, stream_name: "Inventory::Product$#{product.id}")
    UpdateProductStockLevel.new.call(stock_level_increased)
    UpdateProductStockLevel.new.call(stock_level_increased_second_time)

    assert_equal 20, product.reload.stock_level
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
```

Remember to remove updating product from the `ProductService` facade.

<details>
  <summary>Do you pass this test?</summary>

```ruby

def test_life_is_brutal_and_full_of_traps
  product = Product.create!(name: 'Test Product', price: 10, vat_rate: 23, sku: 'test', stock_level: 0)

  stock_level_increased = Inventory::StockLevelIncreased.new(data: { id: product.id, quantity: 10 })
  event_store.append(stock_level_increased, stream_name: "Inventory::Product$#{product.id}")
  UpdateProductStockLevel.new.call(stock_level_increased)
  UpdateProductStockLevel.new.call(stock_level_increased)

  assert_equal 10, product.reload.stock_level
end
```

</details>

### Step 6 - dealing with the problem

First, add checkpoint column to the `Product` active record.

How can we use that information to ensure idempotency?

<details>
<summary>Answer (diff)</summary>

```ruby
-case event
- when Inventory::StockLevelIncreased
-product.increment!(:stock_level, event.data[:quantity])
- when Inventory::StockLevelDecreased
-product.decrement!(:stock_level, event.data[:quantity])
+checkpoint = product.checkpoint
+
+product_stream = event_store.read.stream("Inventory::Product$#{product.id}")
+product_stream = product_stream.from(checkpoint) if checkpoint
+
+product_stream.each do |event|
  +case event
  + when Inventory::StockLevelIncreased
  +product.increment!(:stock_level, event.data[:quantity])
  + when Inventory::StockLevelDecreased
  +product.decrement!(:stock_level, event.data[:quantity])
  +
end
+product.checkpoint = event.event_id
end
+
+product.save!
+
end
+
+private
+
+

def event_store
  +Rails.configuration.event_store
```

</details>

### Step 7 - we can do better

Introduce separate Read Model - `ProductCatalog`. What would be minimum acceptable schema?

<details>
<summary>Schema</summary>

```ruby

class CreateProductCatalogs < ActiveRecord::Migration[7.0]
  def change
    create_table :product_catalogs do |t|
      t.string :checkpoint
      t.integer :product_id
      t.integer :stock_level

      t.timestamps
    end
  end
end

```
</details>

Now introduce event handler to update product catalog. Remember about idempotency.

<details>
<summary>Implementation</summary>

```ruby
module Inventory
  class UpdateProductCatalog
    def call(event)
      product_catalog = ProductCatalog.find_or_initialize_by(product_id: event.data[:id])

      checkpoint = product_catalog.checkpoint

      product_stream = event_store.read.stream("Inventory::Product$#{product_catalog.product_id}")
      product_stream = product_stream.from(checkpoint) if checkpoint

      product_stream.each do |event|
        case event
        when Inventory::StockLevelIncreased
          product_catalog.increment!(:stock_level, event.data[:quantity])
        when Inventory::StockLevelDecreased
          product_catalog.decrement!(:stock_level, event.data[:quantity])
        when Inventory::StockLevelMigrated
          product_catalog.stock_level = event.data[:quantity]
        end
        product_catalog.checkpoint = event.event_id
      end

      product_catalog.save!
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
```
</details>

Adjust tests accordingly.

### Step 8 - product doesnt know about stock level anymore 

First, we need to migrate the data.

Second, remember to switch from using `Product#stock_level` to `ProductCatalog#stock_level`.

Can we drop the `stock_level` column now?
