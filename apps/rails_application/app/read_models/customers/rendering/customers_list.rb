module Customers
  module Rendering
    class CustomersList < ::Arbre::Component
      include Rails.application.routes.url_helpers

      def self.build(view_context, store_id)
        new(::Arbre::Context.new(nil, view_context)).build(Customers.customers_for_store(store_id))
      end

      def build(customers, attributes = {})
        super(attributes)

        table class: "w-full" do
          thead do
            tr do
              th "Name", class: "text-left py-2"
              th "Vip", class: "text-center py-2"
              th "Paid orders summary", class: "text-right py-2"
              th "Account", class: "text-center py-2"
            end
          end

          tbody do
            customers.each { |customer| customer_row(customer) }
          end
        end
      end

      private

      def customer_row(customer)
        tr class: "border-t" do
          name_cell(customer)
          vip_cell(customer)
          summary_cell(customer)
          account_cell(customer)
        end
      end

      def name_cell(customer)
        td class: "py-2" do
          a customer.name, href: customer_path(customer), class: "text-blue-500 hover:underline"
        end
      end

      def vip_cell(customer)
        td class: "py-2 text-center" do
          if customer.vip
            text_node "Already a VIP"
          else
            text_node promote_to_vip_form(customer)
          end
        end
      end

      def summary_cell(customer)
        td class: "py-2 text-right" do
          text_node number_to_currency(customer.paid_orders_summary)
        end
      end

      def account_cell(customer)
        td class: "py-2 text-center" do
          if customer.login.present?
            text_node customer.login
          else
            a "Create account", href: new_customer_account_path(customer), class: "text-blue-500 hover:underline"
          end
        end
      end

      def promote_to_vip_form(customer)
        helpers.form_with(model: customer, url: customer_path(customer.id), id: "form#{customer.id}") do
          helpers.action_button("border-transparent text-white bg-blue-600 hover:bg-blue-700", type: "submit", form: "form#{customer.id}") { "Promote to Vip" }
        end
      end
    end
  end
end
