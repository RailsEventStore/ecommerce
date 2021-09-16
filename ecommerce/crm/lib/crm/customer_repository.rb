module Crm
  class InMemoryCustomerRepository
    def initialize
      @records = {}
    end

    def create(customer)
      @records[customer.id] = customer
      nil
    end

    def find(customer_id)
      @records[customer_id]
    end

    def find_or_initialize_by_id(id)
      find(id) || Customer.new(id: id)
    end

    def all
      @records.values
    end
  end
end