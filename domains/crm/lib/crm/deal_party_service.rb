module Crm
  class OnAssignCompanyToDeal
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(DealParty, command.aggregate_id) do |deal_party|
        deal_party.add_company(command.deal_id, command.company_id)
      end
    end
  end

  class OnAssignContactToDeal
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(DealParty, command.aggregate_id) do |deal_party|
        deal_party.add_contact(command.deal_id, command.contact_id)
      end
    end
  end
end
