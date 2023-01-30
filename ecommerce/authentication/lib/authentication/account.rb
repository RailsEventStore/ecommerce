module Authentication
  class Account
    include AggregateRoot

    AlreadyRegistered = Class.new(StandardError)
    WrongPassword = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register
      raise AlreadyRegistered if @registered

      apply AccountRegistered.new(data: { account_id: @id })
    end

    def set_login(login)
      apply LoginSet.new(data: { account_id: @id, login: login })
    end

    def set_password_hash(password_hash)
      apply PasswordHashSet.new(data: { account_id: @id, password_hash: password_hash })
    end

    def connect_client(client_id)
      apply AccountConnectedToClient.new(data: { account_id: @id, client_id: client_id })
    end

    private

    on AccountRegistered do |event|
      @registered = true
    end

    on LoginSet do |event|
      @login = event.data[:login]
    end

    on PasswordHashSet do |event|
      @password_hash = event.data[:password_hash]
    end

    on AccountConnectedToClient do |event|
      @client_id = event.data[:client_id]
    end
  end
end
