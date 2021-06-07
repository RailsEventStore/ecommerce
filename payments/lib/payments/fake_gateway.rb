module Payments
  class FakeGateway
    def initialize
      @authorized_transactions = []
    end

    def authorize_transaction(transaction_id)
      authorized_transactions << transaction_id
    end

    def authorized_transactions
      @authorized_transactions
    end
  end
end