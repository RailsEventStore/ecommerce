module CommandHandler
  def with_aggregate(aggregate_class, aggregate_id)
    aggregate = aggregate_class.new(aggregate_id)
    aggregate.load(stream_name(aggregate_class, aggregate_id), event_store: Rails.configuration.event_store)
    yield aggregate
    aggregate.store(event_store: Rails.configuration.event_store)
  end

  def rehydrate(aggregate, stream)
    aggregate.load(stream, event_store: Rails.configuration.event_store)
    aggregate
  end

  def stream_name(aggregate_class, aggregate_id)
    "#{aggregate_class.name}$#{aggregate_id}"
  end
end

