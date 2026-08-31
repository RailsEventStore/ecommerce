# frozen_string_literal: true

module HanamiApplication
  module Actions
    module Orders
      class Show < HanamiApplication::Action
        include Deps["read_models.orders"]

        def handle(request, response)
          order_id = request.params[:id]
          halt 404 unless orders.find(order_id)
          response.render(view, order_id: order_id)
        end
      end
    end
  end
end
