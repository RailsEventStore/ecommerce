require "test_helper"

class ReadModelHandlerTest < InMemoryTestCase
  cover "ReadModelHandler*"
  cover "CreateRecord*"
  cover "CopyEventAttribute*"

  def test_create_record
    event = product_registered
    event_store.append(event)
    CreateRecord.new(event_store, PublicOffer::Product, :product_id).call(event)
    assert_equal 1, PublicOffer::Product.count
  end

  def test_dealing_with_at_least_once_delivery
    event = product_registered
    event_store.append(event)
    2.times { CreateRecord.new(event_store, PublicOffer::Product, :product_id).call(event) }
    assert_equal 1, PublicOffer::Product.count
  end

  def test_copy
    event = product_named
    event_store.append(event)
    CopyEventAttribute.new(event_store, PublicOffer::Product, :product_id, :name, :name).call(event)
    assert_equal product_name, PublicOffer::Product.first.name
  end

  def test_copy_nested_attribute
    event = vat_rate_set
    event_store.append(event)
    CopyEventAttribute.new(event_store, Products::Product, :product_id, [:vat_rate, :code], :vat_rate_code).call(event)
    assert_equal available_vat_rate.code, Products::Product.first.vat_rate_code
  end

  def test_no_specific_order_expected
    event = product_registered
    event_store.append(event)
    PublicOffer::Product.create(id: product_id)
    CreateRecord.new(event_store, PublicOffer::Product, :product_id).call(event)
    assert_equal 1, PublicOffer::Product.count
  end

  def test_updating_with_newest_data
    event_store.append(first_event = product_named(product_name))
    event_store.append(second_event = product_named('New name'))

    handler = CopyEventAttribute.new(event_store, PublicOffer::Product, :product_id, :name, :name)
    handler.call(second_event)
    handler.call(first_event)

    assert_equal 'New name', PublicOffer::Product.first.name
  end

  def test_updating_with_newest_data_concurrently
    events = 3.times.map { |i| product_named("#{product_name} #{i}") }
    events += [product_named('New name')]
    events.each { |event| event_store.append(event) }
    handler = CopyEventAttribute.new(event_store, PublicOffer::Product, :product_id, :name, :name)

    assert_equal(5, ActiveRecord::Base.connection.pool.size)

    wait_for_it = true
    threads = events.reverse.map do |event|
      Thread.new do
        true while wait_for_it
        handler.call(event)
      end
    end
    wait_for_it = false
    threads.each(&:join)
    assert_equal 'New name', PublicOffer::Product.first.name
  ensure
    ActiveRecord::Base.connection_pool.disconnect!
  end

  private

  def read_model
    SingleTableReadModel.new(event_store, PublicOffer::Product, :product_id)
  end

  def product_id
    @product_id ||= SecureRandom.uuid
  end

  def product_registered
    ProductCatalog::ProductRegistered.new(data: { product_id: product_id })
  end

  def product_name
    'Valid test name'
  end

  def product_named(name = product_name)
    ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: name })
  end

  def vat_rate_set
    Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: available_vat_rate })
  end

  def available_vat_rate
    Taxes::Configuration.available_vat_rates.first
  end

  def event_store
    Rails.configuration.event_store
  end
end
