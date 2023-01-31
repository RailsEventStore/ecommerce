class SingleTableReadModel
  def initialize(event_store, active_record_name, id_column)
    @event_store = event_store
    @active_record_name = active_record_name
    @id_column = id_column
  end

  def subscribe_create(creation_event)
    _active_record_name_, _id_column_, _event_store_ = @active_record_name, @id_column, @event_store
    @event_store.subscribe(
      Object.const_set(
        "Create#{@active_record_name.name.gsub('::', '')}On#{creation_event.name.gsub('::', '')}",
        Class.new(CreateRecord) do
          define_method(:event_store) { _event_store_ }
          define_method(:active_record_name) { _active_record_name_ }
          define_method(:id_column) { _id_column_ }
        end
      ), to: [creation_event])
  end

  def copy(event, sequence_of_keys, column = Array(sequence_of_keys).first)
    _active_record_name_, _id_column_, _event_store_ = @active_record_name, @id_column, @event_store
    @event_store.subscribe(
      Object.const_set(
        "Set#{@active_record_name.name.gsub('::', '')}#{column.to_s.camelcase}On#{event.name.gsub('::', '')}",
        Class.new(CopyEventAttribute) do
          define_method(:event_store) { _event_store_ }
          define_method(:active_record_name) { _active_record_name_ }
          define_method(:id_column) { _id_column_ }
          define_method(:sequence_of_keys) { sequence_of_keys }
          define_method(:column) { column }
        end
      ), to: [event])
  end
end

class ReadModelHandler < Infra::EventHandler
  def initialize(*args)
    if args.present?
      @event_store = args[0]
      @active_record_name = args[1]
      @id_column = args[2]
    end
    super()
  end

  private

  attr_reader :active_record_name, :id_column, :event_store

  def concurrent_safely(event)
    stream_name = "#{active_record_name}$#{event.data.fetch(id_column)}$#{event.event_type}"
    begin
      past_events = event_store.read.as_at.stream(stream_name)
      last_stored = past_events.count - 1
      event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    rescue RubyEventStore::EventDuplicatedInStream
      return
    else
      return if past_events.last && past_events.last.timestamp > event.timestamp
      yield
    end
  end

  def find_record(event)
    find(event.data.fetch(id_column))
  end

  def find(id)
    active_record_name.lock.find_or_create_by(id: id)
  end
end

class CreateRecord < ReadModelHandler
  def call(event)
    concurrent_safely(event) do
      active_record_name.find_or_create_by(id: event.data.fetch(id_column))
    end
  end
end

class CopyEventAttribute < ReadModelHandler
  def initialize(*args)
    if args.present?
      @sequence_of_keys = args[3]
      @column = args[4]
    end
    super
  end

  def call(event)
    concurrent_safely(event) do
      find_record(event).update_attribute(column, event.data.dig(*sequence_of_keys))
    end
  end

  private
  attr_reader :sequence_of_keys, :column
end