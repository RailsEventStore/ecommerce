class SingleTableReadModel
  def initialize(event_store, active_record_name, id_column)
    @event_store = event_store
    @active_record_name = active_record_name
    @id_column = id_column
  end

  def subscribe_create(creation_event)
    @event_store.subscribe(create_handler(creation_event), to: [creation_event])
  end

  def subscribe_copy(event, sequence_of_keys, column = Array(sequence_of_keys).join('_'))
    @event_store.subscribe(copy_handler(event, sequence_of_keys, column), to: [event])
  end

  private

  def create_handler(event)
    handler_class_name = "Create#{@active_record_name.name.gsub('::', '')}On#{event.name.gsub('::', '')}"
    Object.send(:remove_const, handler_class_name) if self.class.const_defined?(handler_class_name)
    _active_record_name_, _id_column_, _event_store_ = @active_record_name, @id_column, @event_store
    Object.const_set(
      handler_class_name,
      Class.new(CreateRecord) do
        define_method(:event_store) { _event_store_ }
        define_method(:active_record_name) { _active_record_name_ }
        define_method(:id_column) { _id_column_ }
      end
    )
  end

  def copy_handler(event, sequence_of_keys, column)
    handler_class_name = "Set#{@active_record_name.name.gsub('::', '')}#{column.to_s.camelcase}On#{event.name.gsub('::', '')}"
    Object.send(:remove_const, handler_class_name) if self.class.const_defined?(handler_class_name)
    _active_record_name_, _id_column_, _event_store_ = @active_record_name, @id_column, @event_store
    Object.const_set(
      handler_class_name,
      Class.new(CopyEventAttribute) do
        define_method(:event_store) { _event_store_ }
        define_method(:active_record_name) { _active_record_name_ }
        define_method(:id_column) { _id_column_ }
        define_method(:sequence_of_keys) { sequence_of_keys }
        define_method(:column) { column }
      end
    )
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
    stream_name = "#{active_record_name}$#{record_id(event)}$#{event.event_type}"
    read_scope = event_store.read.as_at.stream(stream_name)
    begin
      last_event = read_scope.last
      return if last_event && last_event.timestamp > event.timestamp
      ApplicationRecord.with_advisory_lock(active_record_name, record_id(event)) do
        yield
        event_store.link(
          event.event_id,
          stream_name: stream_name,
          expected_version: last_event ? read_scope.to(last_event.event_id).count : -1
        )
      end
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    rescue RubyEventStore::EventDuplicatedInStream
    end
  end

  def find_or_initialize_record(event)
    active_record_name.find_or_initialize_by(id: record_id(event))
  end

  def record_id(event)
    event.data.fetch(id_column)
  end
end

class CreateRecord < ReadModelHandler
  def call(event)
    concurrent_safely(event) do
      find_or_initialize_record(event).save
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
      find_or_initialize_record(event).update_attribute(column, event.data.dig(*sequence_of_keys))
    end
  end

  private
  attr_reader :sequence_of_keys, :column
end