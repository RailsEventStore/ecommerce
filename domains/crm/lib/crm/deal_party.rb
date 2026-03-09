module Crm
  class DealParty
    include AggregateRoot

    AlreadyCreated = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def add_company(deal_id, company_id)
      raise AlreadyCreated if @created
      apply CompanyAssignedToDeal.new(data: { deal_party_id: @id, deal_id: deal_id, company_id: company_id })
    end

    def add_contact(deal_id, contact_id)
      raise AlreadyCreated if @created
      apply ContactAssignedToDeal.new(data: { deal_party_id: @id, deal_id: deal_id, contact_id: contact_id })
    end

    on CompanyAssignedToDeal do |event|
      @created = true
    end

    on ContactAssignedToDeal do |event|
      @created = true
    end
  end
end
