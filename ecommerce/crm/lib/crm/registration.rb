module Crm
  class Registration
    def initialize(customer_repository = CustomerRepository.new)
      @customer_repository = customer_repository
    end

    def call(cmd)
      customer = @customer_repository.find_or_initialize_by_id(cmd.customer_id)
      customer.register(cmd.name)
      @customer_repository.create(customer)
    end
  end
end