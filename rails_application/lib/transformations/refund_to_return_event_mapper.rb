module Transformations
  class RefundToReturnEventMapper
    def initialize(class_map)
      @class_map = class_map
    end

    def dump(record)
      if ENV['DEBUG_TRANSFORMATIONS'] == 'true'
        puts "[TRANSFORM] dump() called with event_type: #{record.event_type}"
        puts "[TRANSFORM] record class: #{record.class.name}"
        puts "[TRANSFORM] record timestamp: #{record.timestamp.inspect}"
        puts "[TRANSFORM] record valid_at: #{record.valid_at.inspect}"
      end
      record
    end

    def load(record)
      if ENV['DEBUG_TRANSFORMATIONS'] == 'true'
        puts "[TRANSFORM] load() called with event_type: #{record.event_type}"
        puts "[TRANSFORM] record class: #{record.class.name}"
        puts "[TRANSFORM] record timestamp: #{record.timestamp.inspect}"
        puts "[TRANSFORM] record valid_at: #{record.valid_at.inspect}"
      end

      old_class_name = record.event_type
      new_class_name = @class_map.fetch(old_class_name, old_class_name)

      if old_class_name != new_class_name
        if ENV['DEBUG_TRANSFORMATIONS'] == 'true'
          puts "[TRANSFORM] Transforming: #{old_class_name} -> #{new_class_name}"
        end

        transformed_data = transform_payload(record.data, old_class_name)
        new_record = record.class.new(
          event_id: record.event_id,
          event_type: new_class_name,
          data: transformed_data,
          metadata: record.metadata,
          timestamp: record.timestamp || Time.now.utc,
          valid_at: record.valid_at || Time.now.utc
        )

        if ENV['DEBUG_TRANSFORMATIONS'] == 'true'
          puts "[TRANSFORM] Created new record with timestamp: #{new_record.timestamp.inspect}"
        end

        new_record
      else
        record
      end
    end

    private

    def transform_payload(data, old_class_name)
      case old_class_name
      when 'Ordering::DraftRefundCreated'
        data = transform_refund_to_return_payload(data, :refund_id, :return_id)
        transform_refund_to_return_payload(data, :refundable_products, :returnable_products)
      when 'Ordering::ItemAddedToRefund', 'Ordering::ItemRemovedFromRefund'
        transform_refund_to_return_payload(data, :refund_id, :return_id)
      else
        data
      end
    end

    def transform_refund_to_return_payload(data, old_key, new_key)
      if data.key?(old_key)
        data_copy = data.dup
        data_copy[new_key] = data_copy.delete(old_key)
        data_copy
      else
        data
      end
    end
  end
end
