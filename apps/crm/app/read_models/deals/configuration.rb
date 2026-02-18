module Deals
  class Deal < ApplicationRecord
    self.table_name = "deals"
  end
  private_constant :Deal

  def self.all
    Deal.order(id: :asc)
  end

  def self.find_by_uid(uid)
    Deal.find_by!(uid: uid)
  end

  def self.for_pipeline(pipeline_uid)
    Deal.where(pipeline_uid: pipeline_uid).order(id: :asc)
  end

  class CreateDeal
    def call(event)
      Deal.create!(
        uid: event.data.fetch(:deal_id),
        pipeline_uid: event.data.fetch(:pipeline_id),
        name: event.data.fetch(:name)
      )
    end
  end

  class SetValue
    def call(event)
      Deal.find_by!(uid: event.data.fetch(:deal_id)).update!(value: event.data.fetch(:value))
    end
  end

  class SetExpectedCloseDate
    def call(event)
      Deal.find_by!(uid: event.data.fetch(:deal_id)).update!(expected_close_date: event.data.fetch(:expected_close_date))
    end
  end

  class MoveToStage
    def call(event)
      Deal.find_by!(uid: event.data.fetch(:deal_id)).update!(stage: event.data.fetch(:stage))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateDeal.new, to: [Crm::DealCreated])
      event_store.subscribe(SetValue.new, to: [Crm::DealValueSet])
      event_store.subscribe(SetExpectedCloseDate.new, to: [Crm::DealExpectedCloseDateSet])
      event_store.subscribe(MoveToStage.new, to: [Crm::DealMovedToStage])
    end
  end
end
