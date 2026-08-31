# frozen_string_literal: true

module HanamiApplication
  module Actions
    module Cart
      class Show < HanamiApplication::Action
        def handle(request, response)
          response.render(view, order_id: request.session[:order_id])
        end
      end
    end
  end
end
