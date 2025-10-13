module Admin
  module Rendering
    class StoresNew < ::Arbre::Component
      include Rails.application.routes.url_helpers

      def self.build(view_context, store_id, alert)
        new(::Arbre::Context.new(nil, view_context)).build(store_id, alert)
      end

      def build(store_id, alert, attributes = {})
        super(attributes)

        insert_tag Admin::Arbre::TurboFrame, id: "create_store" do
          form action: admin_stores_path, method: :post, id: "form" do
            input type: "hidden", name: "authenticity_token", value: form_authenticity_token
            input type: "hidden", name: "store_id", value: store_id, data: { turbo_permanent: true }

            div do
              label "Name", for: "name", class: "block font-bold"
              input type: "text", name: "name", value: "", required: true, class: "mt-1 focus:ring-blue-500 focus:border-blue-500 block shadow-sm sm:text-sm border-gray-300 rounded-md", data: { turbo_permanent: true }
            end

            if alert
              div class: "mt-2 text-red-600" do
                span alert
              end
            end

            div class: "mt-4" do
              input type: "submit", value: "Create Store", class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 cursor-pointer"
            end
          end
        end
      end
    end
  end
end
