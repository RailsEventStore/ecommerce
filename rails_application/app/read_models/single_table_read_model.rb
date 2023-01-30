class SingleTableReadModel

  def initialize(event_store, active_record_name, id_column)
    @event_store = event_store
    @active_record_name = active_record_name
    @id_column = id_column
  end

  def subscribe_create(creation_event)
    @event_store.subscribe(-> (event) { create_record(event) }, to: [creation_event])
  end

  def copy(event, sequence_of_keys, column = Array(sequence_of_keys).first)
    @event_store.subscribe(-> (event) { copy_event_attribute_to_column(event, sequence_of_keys, column) }, to: [event])
  end

  private

  def create_record(event)
    concurrent_safely(event) do
      @active_record_name.find_or_create_by(id: event.data.fetch(@id_column))
    end
  end

  def copy_event_attribute_to_column(event, sequence_of_keys, column)
    concurrent_safely(event) do
      find_record(event).update_attribute(column, event.data.dig(sequence_of_keys))
    end
  end

  def find_record(event)
    find(event.data.fetch(@id_column))
  end

  def find(id)
    @active_record_name.lock.find_or_create_by(id: id)
  end

  def concurrent_safely(event)
    stream_name = "#{@active_record_name}$#{event.data.fetch(@id_column)}$#{event.event_type}"
    begin
      past_events = @event_store.read.as_at.stream(stream_name)
      last_stored = past_events.count - 1
      @event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    rescue RubyEventStore::EventDuplicatedInStream
      return
    else
      return if past_events.last && past_events.last.timestamp > event.timestamp
      yield
    end
  end
end