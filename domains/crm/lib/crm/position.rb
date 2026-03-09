module Crm
  class Position
    include AggregateRoot

    AlreadyCreated = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def assign_contact_to_company(contact_id, company_id)
      raise AlreadyCreated if @created
      apply ContactAssignedToCompany.new(data: { position_id: @id, contact_id: contact_id, company_id: company_id })
    end

    on ContactAssignedToCompany do |event|
      @created = true
    end
  end
end
