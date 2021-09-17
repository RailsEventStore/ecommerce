module Payments
  class FakeGateway
    def initialize
      @authorized_transactions = []
    end

    def reset
      @authorized_transactions = []
    end

    def authorize_transaction(transaction_id, amount)
      authorized_transactions << [transaction_id, amount]
    end

    def authorized_transactions
      @authorized_transactions
    end
  end
end
