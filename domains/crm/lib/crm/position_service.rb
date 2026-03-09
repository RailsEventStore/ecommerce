module Crm
  class OnAssignContactToCompany
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Position, command.aggregate_id) do |position|
        position.assign_contact_to_company(command.contact_id, command.company_id)
      end
    end
  end
end
