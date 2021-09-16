module Crm
  class CustomerRepository
    class Record < ActiveRecord::Base
      self.table_name = "customers"
    end

    def initialize
      @klass = Customer
    end

    def create(customer)
      Record.create!(**customer.to_h)
      nil
    end

    def find(customer_id)
      Record
        .where(id: customer_id)
        .map(&method(:wrap_record))
        .first
    end

    def find_or_initialize_by_id(id)
      find(id) || @klass.new(id: id)
    end

    def all
      Record.all.map(&method(:wrap_record))
    end

    private

    def wrap_record(r)
      @klass.new(**r.attributes.symbolize_keys)
    end
  end
end