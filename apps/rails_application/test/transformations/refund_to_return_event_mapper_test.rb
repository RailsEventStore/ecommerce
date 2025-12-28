require "test_helper"

class RefundToReturnEventMapperTest < ActiveSupport::TestCase
  def setup
    @mapper = Transformations::RefundToReturnEventMapper.new(
      'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
      'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
      'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
    )
  end

  def test_transforms_refund_id_to_return_id
    record = create_record('Ordering::DraftRefundCreated', { refund_id: 'abc-123' })

    result = @mapper.load(record)

    assert_equal 'return_id', result.data.keys.first.to_s
    assert_equal 'abc-123', result.data[:return_id]
    refute result.data.key?(:refund_id)
  end

  def test_transforms_refundable_products_to_returnable_products
    record = create_record('Ordering::DraftRefundCreated', {
      refund_id: 'abc-123',
      refundable_products: [{ product_id: 'prod-1' }]
    })

    result = @mapper.load(record)

    assert result.data.key?(:returnable_products)
    assert_equal [{ product_id: 'prod-1' }], result.data[:returnable_products]
    refute result.data.key?(:refundable_products)
  end

  def test_transforms_item_added_to_refund
    record = create_record('Ordering::ItemAddedToRefund', { refund_id: 'abc-123' })

    result = @mapper.load(record)

    assert_equal 'Ordering::ItemAddedToReturn', result.event_type
    assert_equal 'abc-123', result.data[:return_id]
    refute result.data.key?(:refund_id)
  end

  def test_transforms_item_removed_from_refund
    record = create_record('Ordering::ItemRemovedFromRefund', { refund_id: 'abc-123' })

    result = @mapper.load(record)

    assert_equal 'Ordering::ItemRemovedFromReturn', result.event_type
    assert_equal 'abc-123', result.data[:return_id]
    refute result.data.key?(:refund_id)
  end

  def test_leaves_unknown_events_unchanged
    record = create_record('SomeOtherEvent', { some_field: 'value' })

    result = @mapper.load(record)

    assert_same record, result
  end

  def test_dump_returns_record_unchanged
    record = create_record('Ordering::DraftRefundCreated', { refund_id: 'abc-123' })

    result = @mapper.dump(record)

    assert_same record, result
  end

  private

  def create_record(event_type, data)
    RubyEventStore::Record.new(
      event_id: SecureRandom.uuid,
      event_type: event_type,
      data: data,
      metadata: {},
      timestamp: Time.current,
      valid_at: Time.current
    )
  end
end
