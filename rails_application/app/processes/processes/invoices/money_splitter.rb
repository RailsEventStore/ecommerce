module Processes
  module Invoices
    class MoneySplitter
      def initialize(amount, quantity)
        @amount = amount
        @weights = Array.new(quantity, 1)
      end

      def call
        distributed_amounts = []
        total_weight = @weights.sum.to_d
        @weights.each do |weight|
          if total_weight.eql?(0)
            distributed_amounts << 0
            next
          end

          p = weight / total_weight
          distributed_amount = (p * @amount).round(2)
          distributed_amounts << distributed_amount
          total_weight -= weight
          @amount -= distributed_amount
        end

        distributed_amounts
      end
    end
  end
end
