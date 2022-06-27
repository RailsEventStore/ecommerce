module HappyHours
  class HappyHour < ApplicationRecord
    self.table_name = "happy_hours"
  end

  class Configuration
    def call(cqrs)
      cqrs.subscribe(
        ->(event) { create_happy_hour(event) },
        [Pricing::HappyHourCreated]
      )
    end

    private

    def create_happy_hour(event)
      event_data = event.data
      uid = event_data.delete(:happy_hour_id)
      HappyHour.create(**event_data.merge(uid: uid))
    end
  end
end
