module Transformations
  class SymbolizeDataKeys
    def dump(record)
      record
    end

    def load(record)
      return record unless record.respond_to?(:data)

      symbolized_data = symbolize_keys(record.data)

      if record.respond_to?(:dup)
        new_record = record.dup
        new_record.instance_variable_set(:@data, symbolized_data) if new_record.instance_variable_defined?(:@data)
        new_record
      else
        record
      end
    end

    private

    def symbolize_keys(hash)
      case hash
      when Hash
        hash.transform_keys(&:to_sym).transform_values { |v| symbolize_keys(v) }
      when Array
        hash.map { |v| symbolize_keys(v) }
      else
        hash
      end
    end
  end
end