module Crm
  class Customer
    AlreadyRegistered = Class.new(StandardError)

    attr_reader :name, :id

    def initialize(**attributes)
      @id, @name, @registered_at = attributes.values_at(:id, :name, :registered_at)
    end

    def register(name)
      raise AlreadyRegistered if @registered_at
      @name = name
      @registered_at = Time.now
    end

    def to_h
      { name: name, id: id, registered_at: @registered_at }
    end
  end
end