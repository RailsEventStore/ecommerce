module Claims
  class FakeGateway
    def initialize
      @paid_out_transactions = []
    end

    def reset
      @paid_out_transactions = []
    end

    def pay_out(claim_id, amount)
      paid_out_transactions << [claim_id, amount]
    end

    def paid_out_transactions
      @paid_out_transactions
    end
  end
end
