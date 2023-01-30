require "test_helper"

class SingleTableReadModelTest < InMemoryTestCase
  cover "SingleTableReadModel*"

  def test_subscribe_create
    event = product_registered
    event_store.append(event)
    read_model.send :create_record, event
    assert_equal 1, PublicOffer::Product.count
  end

  def test_dealing_with_at_least_once_delivery
    event = product_registered
    event_store.append(event)
    2.times { read_model.send :create_record, event }
    assert_equal 1, PublicOffer::Product.count
  end

  def test_copy
    event_store.publish(product_named)
    assert_equal product_name, PublicOffer::Product.first.name
  end

  def test_dealing_with_no_order_guarantee
    event_store.append(first_event = product_named(product_name))
    event_store.append(second_event = product_named('New name'))

    read_model.send :copy_event_attribute_to_column, second_event, :name, :name
    read_model.send :copy_event_attribute_to_column, first_event, :name, :name

    assert_equal 'New name', PublicOffer::Product.first.name
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

  def event_store
    Rails.configuration.event_store
  end
end
