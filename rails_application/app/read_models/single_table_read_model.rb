class SingleTableReadModel

  def initialize(event_store, active_record_name, id_column)
    @event_store = event_store
    @active_record_name = active_record_name
    @id_column = id_column
  end

  def subscribe_create(creation_event)
    @event_store.subscribe(-> (event) { create_record(event, @id_column) }, to: [creation_event])
  end

  def copy(event, attribute)
    @event_store.subscribe(-> (event) { copy_event_attribute_to_column(event, attribute, attribute) }, to: [event])
  end

  def copy_nested_to_column(event, top_event_attribute, nested_attribute, column)
    @event_store.subscribe(
      -> (event) { copy_nested_event_attribute_to_column(event, top_event_attribute, nested_attribute, column) }, to: [event])
  end

  private

  def create_record(event, id_column)
    concurrent_safely(event) do
      @active_record_name.find_or_create_by(id: event.data.fetch(id_column))
    end
  end

  def copy_event_attribute_to_column(event, event_attribute, column)
    concurrent_safely(event) do
      find_record(event).update_attribute(column, event.data.fetch(event_attribute))
    end
  end

  def copy_nested_event_attribute_to_column(event, top_event_attribute, nested_attribute, column)
    concurrent_safely(event) do
      find_record(event).update_attribute(column, event.data.fetch(top_event_attribute).fetch(nested_attribute))
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
      past_events = @event_store.read.stream(stream_name).to_a
      last_stored = past_events.size - 1
      @event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    rescue RubyEventStore::EventDuplicatedInStream
      return
    else
      return if past_events.any? && past_events.last.timestamp > event.timestamp
      yield
    end
  end
end