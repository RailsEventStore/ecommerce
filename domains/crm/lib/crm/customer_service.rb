module Crm

  class OnRegistration
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Customer, command.aggregate_id) do |customer|
        customer.register(command.name)
      end
    end
  end

  class OnPromoteCustomerToVip
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Customer, command.aggregate_id) do |customer|
        customer.promote_to_vip
      end
    end
  end

end