module Denormalizers
  class OrderExpired < ApplicationJob
    queue_as :default

    def perform(*args)
      call(YAML.load(args.first))
    end

    private
    def call(event)
      order = ::Order.find_by_uid(event.data[:order_id])
      order.state = "Expired"
      order.save!
    end
  end
end
