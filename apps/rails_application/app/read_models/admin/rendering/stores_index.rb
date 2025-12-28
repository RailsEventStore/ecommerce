module Admin
  module Rendering
    class StoresIndex < ::Arbre::Component
      include Rails.application.routes.url_helpers

      def self.build(view_context)
        new(::Arbre::Context.new(nil, view_context)).build(stores)
      end

      def build(stores, attributes = {})
        super(attributes)

        div do
          div class: "flex justify-between items-center mb-4" do
            h2 "Stores", class: "text-2xl font-bold"
            a "New Store", href: new_admin_store_path, class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
          end

          table class: "w-full" do
            thead do
              tr do
                th "ID", class: "text-left py-2"
                th "Name", class: "text-left py-2"
                th "Actions", class: "text-right py-2"
              end
            end

            tbody do
              stores.each do |store|
                tr class: "border-t" do
                  td store.id, class: "py-2"
                  td store.name, class: "py-2"
                  td class: "py-2 text-right" do
                    a "Edit", href: edit_admin_store_path(store), class: "hover:underline text-blue-500"
                  end
                end
              end
            end
          end
        end
      end

      private

      def self.stores
        Admin::Store.all.to_a
      end
    end
  end
end
