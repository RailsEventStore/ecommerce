module Ecommerce
  module Actions
    module Orders
      class Create < Ecommerce::Action
        include Deps[
          "command_bus",
          "repositories.orders",
        ]

        def handle(request, response)
          submit_order(request.params[:order_id], request.params[:customer_id])

          response.format = :json
          response.body = orders.by_uuid(request.params[:order_id])
            .attributes
            .slice(:uuid)
            .to_json
        end

        private

        def submit_order(order_id, customer_id)
          command_bus.(Ordering::SubmitOrder.new(order_id: order_id))
          # command_bus.(Crm::AssignCustomerToOrder.new(order_id: order_id, customer_id: customer_id))
        end
      end
    end
  end
end
