module ClaimList
  class Claim < ApplicationRecord
    self.table_name = "claims"
  end

  private_constant :Claim

  def self.all
    Claim.order(id: :desc)
  end

  class EventHandler
    def call(event)
      case event
      when Claims::LossReported
        Claim.create!(
          claim_id: event.data.fetch(:claim_id),
          policy_id: event.data.fetch(:policy_id),
          description: event.data.fetch(:description),
          state: "reported"
        )
      when Claims::LossAssessed
        find_claim(event).update!(amount: event.data.fetch(:amount), state: "assessed")
      when Claims::ClaimSettled
        find_claim(event).update!(state: "settled")
      end
    end

    private

    def find_claim(event)
      Claim.find_by!(claim_id: event.data.fetch(:claim_id))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(EventHandler.new, to: [
        Claims::LossReported,
        Claims::LossAssessed,
        Claims::ClaimSettled
      ])
    end
  end
end
