module ClientOrders
  module Rendering
    class FreeProductSaving
      def call(saving)
        Arbre::Context.new do
          td(class: "py-2", colspan: 4) { "3+1 — cheapest item free" }
          td(class: "py-2") { "-#{ActiveSupport::NumberHelper.number_to_currency(saving)}" }
        end.rstrip.html_safe
      end
    end
  end
end
