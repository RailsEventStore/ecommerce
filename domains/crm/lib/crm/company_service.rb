module Crm
  class OnRegisterCompany
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Company, command.aggregate_id) do |company|
        company.register(command.name)
      end
    end
  end

  class OnSetCompanyLinkedinUrl
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Company, command.aggregate_id) do |company|
        company.set_linkedin_url(command.linkedin_url)
      end
    end
  end
end
