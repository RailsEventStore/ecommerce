module Ecommerce
  module Actions
    module Orders
      class Index < Ecommerce::Action
        def handle(request, response)
          response.render(view)
        end
      end
    end
  end
end
