module ClientOrders
  module Rendering
    class SubmitButton
      def self.call(order_id)
        Arbre::Context.new do
          if OrderLine.exists?(order_uid: order_id)
            div(class: "mt-8") do
              input(type: :submit, value: "Create Order", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-xs")
            end
          end
        end.to_str
      end
    end
  end
end
