module Authentication
  class OnRegistration
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Account, command.aggregate_id) do |account|
        account.register
      end
    end
  end

  class OnLoginSet
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Account, command.aggregate_id) do |account|
        account.set_login(command.login)
      end
    end
  end
end
