module Activities
  class Activity < ApplicationRecord
    self.table_name = "activities"
  end
  private_constant :Activity

  def self.all
    Activity.order(occurred_at: :desc)
  end

  def self.recent(limit)
    Activity.order(occurred_at: :desc).limit(limit)
  end

  class OnContactRegistered
    def call(event)
      Activity.create!(
        entity_type: "contact",
        entity_uid: event.data.fetch(:contact_id),
        action: "Contact registered: #{event.data.fetch(:name)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnContactEmailSet
    def call(event)
      Activity.create!(
        entity_type: "contact",
        entity_uid: event.data.fetch(:contact_id),
        action: "Contact email set: #{event.data.fetch(:email)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnContactPhoneSet
    def call(event)
      Activity.create!(
        entity_type: "contact",
        entity_uid: event.data.fetch(:contact_id),
        action: "Contact phone set: #{event.data.fetch(:phone)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnContactLinkedinUrlSet
    def call(event)
      Activity.create!(
        entity_type: "contact",
        entity_uid: event.data.fetch(:contact_id),
        action: "Contact LinkedIn URL set: #{event.data.fetch(:linkedin_url)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnCompanyRegistered
    def call(event)
      Activity.create!(
        entity_type: "company",
        entity_uid: event.data.fetch(:company_id),
        action: "Company registered: #{event.data.fetch(:name)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnCompanyLinkedinUrlSet
    def call(event)
      Activity.create!(
        entity_type: "company",
        entity_uid: event.data.fetch(:company_id),
        action: "Company LinkedIn URL set: #{event.data.fetch(:linkedin_url)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnPipelineCreated
    def call(event)
      Activity.create!(
        entity_type: "pipeline",
        entity_uid: event.data.fetch(:pipeline_id),
        action: "Pipeline created: #{event.data.fetch(:name)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnStageAddedToPipeline
    def call(event)
      Activity.create!(
        entity_type: "pipeline",
        entity_uid: event.data.fetch(:pipeline_id),
        action: "Stage added to pipeline: #{event.data.fetch(:stage_name)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnStageRemovedFromPipeline
    def call(event)
      Activity.create!(
        entity_type: "pipeline",
        entity_uid: event.data.fetch(:pipeline_id),
        action: "Stage removed from pipeline: #{event.data.fetch(:stage_name)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnDealCreated
    def call(event)
      Activity.create!(
        entity_type: "deal",
        entity_uid: event.data.fetch(:deal_id),
        action: "Deal created: #{event.data.fetch(:name)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnDealValueSet
    def call(event)
      Activity.create!(
        entity_type: "deal",
        entity_uid: event.data.fetch(:deal_id),
        action: "Deal value set: #{event.data.fetch(:value)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnDealExpectedCloseDateSet
    def call(event)
      Activity.create!(
        entity_type: "deal",
        entity_uid: event.data.fetch(:deal_id),
        action: "Deal expected close date set: #{event.data.fetch(:expected_close_date)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnDealMovedToStage
    def call(event)
      Activity.create!(
        entity_type: "deal",
        entity_uid: event.data.fetch(:deal_id),
        action: "Deal moved to stage: #{event.data.fetch(:stage)}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnContactAssignedToCompany
    def call(event)
      contact_name = Contacts.find_by_uid(event.data.fetch(:contact_id)).name
      company_name = Companies.find_by_uid(event.data.fetch(:company_id)).name
      Activity.create!(
        entity_type: "contact",
        entity_uid: event.data.fetch(:contact_id),
        action: "#{contact_name} assigned to company: #{company_name}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnCompanyAssignedToDeal
    def call(event)
      deal_name = Deals.find_by_uid(event.data.fetch(:deal_id)).name
      company_name = Companies.find_by_uid(event.data.fetch(:company_id)).name
      Activity.create!(
        entity_type: "deal",
        entity_uid: event.data.fetch(:deal_id),
        action: "#{company_name} assigned to deal: #{deal_name}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class OnContactAssignedToDeal
    def call(event)
      deal_name = Deals.find_by_uid(event.data.fetch(:deal_id)).name
      contact_name = Contacts.find_by_uid(event.data.fetch(:contact_id)).name
      Activity.create!(
        entity_type: "deal",
        entity_uid: event.data.fetch(:deal_id),
        action: "#{contact_name} assigned to deal: #{deal_name}",
        occurred_at: event.metadata.fetch(:timestamp)
      )
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(OnContactRegistered.new, to: [Crm::ContactRegistered])
      event_store.subscribe(OnContactEmailSet.new, to: [Crm::ContactEmailSet])
      event_store.subscribe(OnContactPhoneSet.new, to: [Crm::ContactPhoneSet])
      event_store.subscribe(OnContactLinkedinUrlSet.new, to: [Crm::ContactLinkedinUrlSet])
      event_store.subscribe(OnCompanyRegistered.new, to: [Crm::CompanyRegistered])
      event_store.subscribe(OnCompanyLinkedinUrlSet.new, to: [Crm::CompanyLinkedinUrlSet])
      event_store.subscribe(OnPipelineCreated.new, to: [Crm::PipelineCreated])
      event_store.subscribe(OnStageAddedToPipeline.new, to: [Crm::StageAddedToPipeline])
      event_store.subscribe(OnStageRemovedFromPipeline.new, to: [Crm::StageRemovedFromPipeline])
      event_store.subscribe(OnDealCreated.new, to: [Crm::DealCreated])
      event_store.subscribe(OnDealValueSet.new, to: [Crm::DealValueSet])
      event_store.subscribe(OnDealExpectedCloseDateSet.new, to: [Crm::DealExpectedCloseDateSet])
      event_store.subscribe(OnDealMovedToStage.new, to: [Crm::DealMovedToStage])
      event_store.subscribe(OnContactAssignedToCompany.new, to: [Crm::ContactAssignedToCompany])
      event_store.subscribe(OnCompanyAssignedToDeal.new, to: [Crm::CompanyAssignedToDeal])
      event_store.subscribe(OnContactAssignedToDeal.new, to: [Crm::ContactAssignedToDeal])
    end
  end
end
