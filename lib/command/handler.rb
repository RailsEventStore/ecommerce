module Command
  module Handler
    def with_aggregate(aggregate_class, aggregate_id)
      stream = "#{aggregate_class.name}$#{aggregate_id}"
      aggregate = aggregate_class.new(aggregate_id).load(stream, event_store: Rails.configuration.event_store)
      yield aggregate
      aggregate.store(event_store: Rails.configuration.event_store)
    end
  end
end
