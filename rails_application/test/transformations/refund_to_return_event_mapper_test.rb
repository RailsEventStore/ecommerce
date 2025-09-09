require "test_helper"

class RefundToReturnEventMapperTest < ActiveSupport::TestCase
  def setup
    @remapper = Transformations::RefundToReturnEventMapper.new(
      'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
      'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
      'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
    )
  end

  def test_maps_event_class_names
    test_cases = [
      ['Ordering::DraftRefundCreated', 'Ordering::DraftReturnCreated'],
      ['Ordering::ItemAddedToRefund', 'Ordering::ItemAddedToReturn'],
      ['Ordering::ItemRemovedFromRefund', 'Ordering::ItemRemovedFromReturn']
    ]

    test_cases.each do |old_name, expected_new_name|
      event_data = {
        event_type: old_name,
        data: { id: SecureRandom.uuid },
        metadata: {}
      }
      
      result = @remapper.load(event_data)
      
      assert_equal expected_new_name, result[:event_type], "Failed to map #{old_name}"
    end
  end

  def test_leaves_new_event_names_unchanged
    new_event_data = {
      event_type: 'Ordering::DraftReturnCreated',
      data: { return_id: SecureRandom.uuid },
      metadata: {}
    }
    
    result = @remapper.load(new_event_data)
    
    assert_equal new_event_data, result
  end

  def test_leaves_unrelated_events_unchanged
    unrelated_event_data = {
      event_type: 'SomeOther::Event',
      data: { id: SecureRandom.uuid },
      metadata: {}
    }
    
    result = @remapper.load(unrelated_event_data)
    
    assert_equal unrelated_event_data, result
  end

  def test_transforms_draft_created_payload_completely
    refund_id = SecureRandom.uuid
    order_id = SecureRandom.uuid
    
    old_event_data = {
      event_type: 'Ordering::DraftRefundCreated',
      data: { refund_id: refund_id, order_id: order_id, refundable_products: [] },
      metadata: {}
    }
    
    result = @remapper.load(old_event_data)
    
    assert_equal refund_id, result[:data][:return_id]
    assert_equal [], result[:data][:returnable_products]
    assert_nil result[:data][:refund_id]
    assert_nil result[:data][:refundable_products]
    assert_equal order_id, result[:data][:order_id]
  end

  def test_transforms_item_events_payload
    refund_id = SecureRandom.uuid
    
    test_cases = [
      'Ordering::ItemAddedToRefund', 
      'Ordering::ItemRemovedFromRefund'
    ]
    
    test_cases.each do |old_event_type|
      old_event_data = {
        event_type: old_event_type,
        data: { refund_id: refund_id, order_id: SecureRandom.uuid, product_id: SecureRandom.uuid },
        metadata: {}
      }
      
      result = @remapper.load(old_event_data)
      
      assert_equal refund_id, result[:data][:return_id], "Failed to transform refund_id to return_id for #{old_event_type}"
      assert_nil result[:data][:refund_id], "refund_id should be removed for #{old_event_type}"
    end
  end

  def test_dump_returns_item_unchanged
    event_data = {
      event_type: 'Ordering::DraftReturnCreated',
      data: { return_id: SecureRandom.uuid },
      metadata: {}
    }
    
    result = @remapper.dump(event_data)

    assert_equal event_data, result
  end

  def test_event_store_with_simple_transformation
    mapper = RubyEventStore::Mappers::PipelineMapper.new(
      RubyEventStore::Mappers::Pipeline.new(
        Transformations::RefundToReturnEventMapper.new(
          'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
          'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
          'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
        )
      )
    )
    
    event_store = RailsEventStore::Client.new(
      repository: RubyEventStore::InMemoryRepository.new,
      mapper: mapper
    )

    return_id = SecureRandom.uuid
    order_id = SecureRandom.uuid

    old_event = Ordering::ItemAddedToReturn.new(
      data: { 
        return_id: return_id,
        order_id: order_id,
        product_id: SecureRandom.uuid
      }
    )

    event_store.publish(old_event, stream_name: "Return$#{return_id}")

    events = event_store.read.stream("Return$#{return_id}").to_a

    assert_equal 1, events.size
    assert_equal 'Ordering::ItemAddedToReturn', events.first.class.name
    assert_equal return_id, events.first.data[:return_id]
    assert_nil events.first.data[:refund_id]
  end
end
