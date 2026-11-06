# frozen_string_literal: true

module HanamiApplication
  module Actions
    module Cart
      class Submit < HanamiApplication::Action
        include Deps["command_bus", "event_store"]

        def handle(request, response)
          order_id = request.session[:order_id]
          unless order_id
            response.flash[:alert] = "Your cart is empty"
            response.redirect_to routes.path(:root)
          end

          rejection = nil
          event_store
            .within { command_bus.call(Pricing::RequestOrderAcceptance.new(order_id)) }
            .subscribe(to: Pricing::EmptyOrderAcceptanceRejected) do |event|
              rejection = event if event.data.fetch(:order_id) == order_id
            end
            .call

          if rejection
            response.flash[:alert] = "Your cart is empty"
            response.redirect_to routes.path(:root)
          end

          request.session[:order_id] = nil
          response.redirect_to routes.path(:order, id: order_id)
        end
      end
    end
  end
end
