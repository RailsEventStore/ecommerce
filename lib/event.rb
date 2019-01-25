require 'time'

class Event < Dry::Struct
  transform_keys(&:to_sym)

  def self.new(data: {}, metadata: {}, **rest)
    timestamp = Time.parse(metadata.delete(:timestamp)) rescue nil
    super(rest.merge(data).merge(metadata: metadata.merge(timestamp: timestamp)))
  end

  def self.inherited(klass)
    super
    klass.attribute :metadata, Types.Constructor(RubyEventStore::Metadata).default { RubyEventStore::Metadata.new }
    klass.attribute :event_id, Types::UUID.default { SecureRandom.uuid }
  end

  def to_h
    {
      event_id: event_id,
      metadata: metadata,
      data:     super.except(:event_id, :metadata)
    }
  end

  def timestamp
    metadata[:timestamp]
  end

  def data
    to_h[:data]
  end

  def type
    self.class.name
  end

  def ==(other_event)
    other_event.instance_of?(self.class) &&
      other_event.event_id.eql?(event_id) &&
      other_event.data.eql?(data)
  end

  alias_method :eql?, :==
end
