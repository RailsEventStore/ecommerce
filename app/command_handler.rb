module CommandHandler
  def with_aggregate(aggregate_id)
    aggregate = build(aggregate_id)
    yield aggregate
    publish(aggregate.changes, aggregate_id)
  end

  private
  def build(aggregate_id)
    aggregate = aggregate_class.new(aggregate_id)
    events = load_events(aggregate_id)
    if events.present?
      aggregate.rebuild(events)
    end
    aggregate
  end

  def load_events(aggregate_id)
    events = event_store.read_all_events(aggregate_id)
    events.map(&:recreate_event)
  end

  def recreate_event(event)
    event_class = "Events::#{event.event_type}".constantize
    event_class.new(event.data)
  end

  def publish(events, stream)
    Array.wrap(events).each do |event|
      event_store.publish(event, stream)
    end
  end

  def event_store
    @event_store ||= RailsEventStore::Client.new
  end
end
