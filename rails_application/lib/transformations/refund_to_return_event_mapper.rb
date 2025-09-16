module Transformations
  class RefundToReturnEventMapper
    def initialize(class_map)
      @class_map = class_map
    end

    def dump(record)
      record
    end

    def load(record)
      old_class_name = record.event_type
      new_class_name = @class_map.fetch(old_class_name, old_class_name)

      if old_class_name != new_class_name
        transformed_data = transform_payload(record.data, old_class_name)
        begin
          metadata_json = record.metadata.respond_to?(:to_json) ? record.metadata.to_json : record.metadata.to_h.to_json
          RubyEventStore::SerializedRecord.new(
            event_id: record.event_id,
            event_type: new_class_name,
            data: transformed_data.to_json,
            metadata: metadata_json,
            timestamp: record.timestamp,
            valid_at: record.valid_at
          )
        rescue => e
          puts "Mapper error: #{e.message}, falling back to original record"
          record
        end
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
