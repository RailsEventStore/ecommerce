module Infra
  class Command < Dry::Struct
    Invalid = Class.new(StandardError)

    def self.new(*)
      super
    rescue Dry::Struct::Error => doh
      raise Invalid, doh
    end
  end
end
