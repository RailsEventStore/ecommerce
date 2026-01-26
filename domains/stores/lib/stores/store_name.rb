module Stores
  StoreName = Data.define(:value) do
    def initialize(value:)
      raise ArgumentError if value.nil? || value.empty?
      super
    end
  end
end
