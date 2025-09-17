require "test_helper"

class RefundToReturnEventMapperIntegrationTest < ActiveSupport::TestCase
  def setup
    @mapper = RubyEventStore::Mappers::PipelineMapper.new(
      RubyEventStore::Mappers::Pipeline.new(
        Transformations::RefundToReturnEventMapper.new(
          'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
          'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
          'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
        )
      )
    )

    @event_store = RailsEventStore::Client.new(
      repository: RubyEventStore::InMemoryRepository.new,
      mapper: @mapper
    )
  end

  def test_transforms_old_events_when_reading
    stream = "Test$#{SecureRandom.uuid}"

    old_event = Ordering::DraftReturnCreated.new(
      data: { return_id: SecureRandom.uuid, order_id: SecureRandom.uuid, returnable_products: [] }
    )

    @event_store.publish(old_event, stream_name: stream)
    events = @event_store.read.stream(stream).to_a

    assert_equal 1, events.size
    assert_equal 'Ordering::DraftReturnCreated', events.first.class.name
  end

  def test_new_events_work_normally
    stream = "Test$#{SecureRandom.uuid}"

    new_event = Ordering::ItemAddedToReturn.new(
      data: { return_id: SecureRandom.uuid, order_id: SecureRandom.uuid, product_id: SecureRandom.uuid }
    )

    @event_store.publish(new_event, stream_name: stream)
    events = @event_store.read.stream(stream).to_a

    assert_equal 1, events.size
    assert_equal 'Ordering::ItemAddedToReturn', events.first.class.name
    assert_not_nil events.first.data[:return_id]
  end
end
