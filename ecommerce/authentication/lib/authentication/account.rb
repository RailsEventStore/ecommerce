module Authentication
  class Account
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)

    def initialize(id)
      @id = id
      @login = nil
    end

    def register
      raise AlreadyRegistered if @registered

      apply AccountRegistered.new(data: { account_id: @id })
    end

    def set_login(login)
      apply LoginSet.new(data: { account_id: @id, login: login })
    end

    on AccountRegistered do |event|
      @registered = true
    end

    on LoginSet do |event|
      @login = event.data[:login]
    end
  end
end
