module Authentication
  class SetLogin
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :account_id, :login

    alias aggregate_id account_id

    def initialize(account_id, login)
      @account_id = account_id
      @login = login
      valid = UUID.match?(@account_id) && @login.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
