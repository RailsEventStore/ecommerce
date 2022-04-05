module Persistence
  module Relations
    class CrmCustomers < ROM::Relation[:sql]
      schema(:crm_customers, infer: true) do
      end
    end
  end
end
