module Applications
  class Application < ApplicationRecord
    self.table_name = "applications"
  end

  private_constant :Application

  def self.all
    Application.order(id: :desc)
  end

  class EventHandler
    def call(event)
      case event
      when Underwriting::ApplicationSubmitted
        Application.create!(
          application_id: event.data.fetch(:application_id),
          coverage_amount: event.data.fetch(:coverage_amount),
          state: "submitted"
        )
      when Underwriting::RiskEvaluated
        find_application(event).update!(risk_class: event.data.fetch(:risk_class), state: "risk evaluated")
      when Underwriting::PremiumCalculated
        find_application(event).update!(premium: event.data.fetch(:premium), state: "priced")
      when Underwriting::OfferAccepted
        find_application(event).update!(state: "accepted")
      end
    end

    private

    def find_application(event)
      Application.find_by!(application_id: event.data.fetch(:application_id))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(EventHandler.new, to: [
        Underwriting::ApplicationSubmitted,
        Underwriting::RiskEvaluated,
        Underwriting::PremiumCalculated,
        Underwriting::OfferAccepted
      ])
    end
  end
end
