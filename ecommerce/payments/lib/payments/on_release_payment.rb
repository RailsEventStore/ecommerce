module Payments
  class OnReleasePayment
    def initialize
      @repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
    end

    def call(command)
      @repository.with_aggregate(Payment.new, "Payments::Payment$#{command.order_id}") do |payment|
        payment.release
      end
    end
  end
end
