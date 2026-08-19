module ClientOrders
  module Rendering
    class FreeProductSaving
      def self.call(saving)
        Arbre::Context.new do
          td(class: "py-2", colspan: 4) { "3+1 — cheapest item free" }
          td(class: "py-2") { "-#{ActiveSupport::NumberHelper.number_to_currency(saving)}" }
        end.to_str
      end
    end
  end
end
