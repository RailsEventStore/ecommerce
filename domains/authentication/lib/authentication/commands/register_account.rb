module Authentication
  class RegisterAccount
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :account_id

    alias aggregate_id account_id

    def initialize(account_id)
      @account_id = account_id
      valid = UUID.match?(@account_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
