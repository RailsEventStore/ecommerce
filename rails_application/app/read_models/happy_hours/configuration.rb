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
      event_data = event.data[:details]
      HappyHour.create(**event_data.merge(id: event.data[:id]))
    end
  end
end
