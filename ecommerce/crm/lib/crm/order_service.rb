module Crm
  class OnSetCustomer
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(command)
      raise Customer::NotExists unless customer_exists?(command.customer_id)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.set_customer(command.customer_id)
      end
    end

    private

    def customer_exists?(customer_id)
      customer_stream = @repository.stream_name(Customer, customer_id)
      !@event_store.read.stream(customer_stream).count.eql?(0)
    end
  end
end