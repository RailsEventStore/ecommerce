module PolicyList
  class Policy < ApplicationRecord
    self.table_name = "policies"
  end

  private_constant :Policy

  def self.all
    Policy.order(id: :desc)
  end

  class EventHandler
    def call(event)
      case event
      when Policies::PolicyIssued
        Policy.create!(
          policy_id: event.data.fetch(:policy_id),
          premium: event.data.fetch(:premium),
          state: "issued"
        )
      when Policies::PolicyInForce
        find_policy(event).update!(state: "in force")
      when Policies::PolicyTerminated
        find_policy(event).update!(state: "terminated")
      end
    end

    private

    def find_policy(event)
      Policy.find_by!(policy_id: event.data.fetch(:policy_id))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(EventHandler.new, to: [
        Policies::PolicyIssued,
        Policies::PolicyInForce,
        Policies::PolicyTerminated
      ])
    end
  end
end
