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
    events.map{|ev| recreate_event(ev) }
  end

  def recreate_event(event)
    event.event_type.constantize.new(event_id: event.event_id,
                                     data: event.data,
                                     metadata: event.metadata)
  end

  def publish(events, stream)
    Array.wrap(events).each do |event|
      event_store.publish_event(event, stream)
    end
  end

  def event_store
    @event_store ||= RailsEventStore::Client.new.tap do |es|
      es.subscribe(Denormalizers::Router.new)
    end
  end
end
