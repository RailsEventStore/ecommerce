module Authentication
  class Account
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register
      raise AlreadyRegistered if @registered

      apply AccountRegistered.new(data: { account_id: @id })
    end

    on AccountRegistered do |event|
      @registered = true
    end
  end
end
