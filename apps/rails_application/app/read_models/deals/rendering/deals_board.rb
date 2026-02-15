module Deals
  module Rendering
    class DealsBoard < Arbre::Component
      include ActionView::Helpers::NumberHelper

      STAGES = ["Draft", "Pending Payment", "Won", "Lost"]

      def self.build(view_context, deals)
        new(Arbre::Context.new(nil, view_context)).build(deals)
      end

      def build(deals, attributes = {})
        super(attributes)

        div class: "flex gap-4 overflow-x-auto" do
          STAGES.each do |stage|
            stage_column(stage, deals.select { |d| d.stage == stage })
          end
        end
      end

      private

      def stage_column(stage, deals)
        div class: "flex-1 min-w-[250px] bg-gray-50 rounded-lg p-4" do
          div class: "flex justify-between items-center mb-3" do
            h3 stage, class: "font-semibold text-gray-700"
            span deals.size.to_s, class: "text-sm text-gray-500 bg-gray-200 rounded-full px-2 py-0.5"
          end

          div class: "space-y-2" do
            deals.each { |deal| deal_card(deal) }
          end
        end
      end

      def deal_card(deal)
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-3" do
          div class: "font-medium text-gray-900 text-sm" do
            deal.order_number || "No number"
          end
          div class: "text-gray-600 text-sm mt-1" do
            deal.customer_name || "No customer"
          end
          div class: "text-gray-800 font-semibold text-sm mt-2" do
            number_to_currency(deal.value || 0)
          end
        end
      end
    end
  end
end
