require "active_support/core_ext/hash"

module Infra
  class Event < RubyEventStore::Event
    module WithSchema
      class Schema < Dry::Struct
        transform_keys(&:to_sym)
      end

      module ClassMethods
        extend Forwardable
        def_delegators :schema, :attribute, :attribute?

        def schema
          @schema ||= Class.new(Schema)
        end
      end

      module Constructor
        def initialize(event_id: SecureRandom.uuid, metadata: nil, data: {})
          super(event_id: event_id, metadata: metadata, data: data.deep_merge(self.class.schema.new(data.deep_symbolize_keys).to_h))
        end
      end

      def self.included(klass)
        klass.extend  WithSchema::ClassMethods
        klass.include WithSchema::Constructor
      end
    end
    include WithSchema
  end
end
