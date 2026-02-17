module Crm
  class OnRegisterContact
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Contact, command.aggregate_id) do |contact|
        contact.register(command.name)
      end
    end
  end

  class OnSetContactEmail
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Contact, command.aggregate_id) do |contact|
        contact.set_email(command.email)
      end
    end
  end

  class OnSetContactPhone
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Contact, command.aggregate_id) do |contact|
        contact.set_phone(command.phone)
      end
    end
  end

  class OnSetContactLinkedinUrl
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Contact, command.aggregate_id) do |contact|
        contact.set_linkedin_url(command.linkedin_url)
      end
    end
  end
end
