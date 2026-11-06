# frozen_string_literal: true

module HanamiApplication
  module Actions
    module Cart
      class Submit < HanamiApplication::Action
        include Deps["command_bus"]

        def handle(request, response)
          order_id = request.session[:order_id]
          unless order_id
            response.flash[:alert] = "Your cart is empty"
            response.redirect_to routes.path(:root)
          end

          command_bus.call(Pricing::RequestOrderAcceptance.new(order_id))
          request.session[:order_id] = nil
          response.redirect_to routes.path(:order, id: order_id)
        rescue HanamiApplication::Processes::OrderAcceptance::IsEmpty
          response.flash[:alert] = "Your cart is empty"
          response.redirect_to routes.path(:root)
        end
      end
    end
  end
end
