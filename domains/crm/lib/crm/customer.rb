module Crm
  class Customer
    include AggregateRoot

    AlreadyVip = Class.new(StandardError)
    AlreadyRegistered = Class.new(StandardError)
    NotExists = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register(name)
      raise AlreadyRegistered if @registered
      apply CustomerRegistered.new(
          data: {
              customer_id: @id,
              name: name
          }
        )
    end

    def promote_to_vip
      raise AlreadyVip if @vip
      apply CustomerPromotedToVip.new(
          data: {
            customer_id: @id
          }
        )
    end

    on CustomerRegistered do |event|
      @registered = true
    end

    on CustomerPromotedToVip do |event|
      @vip = true
    end
  end
end
