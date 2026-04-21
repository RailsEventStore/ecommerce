require "test_helper"

module Customers
  module Rendering
    class CustomersListTest < InMemoryTestCase
      cover "Customers::Rendering::CustomersList*"

      def configure(event_store, _command_bus)
        Customers::Configuration.new.call(event_store)
      end

      def test_renders_customer_with_login
        store_id = SecureRandom.uuid
        customer_id = SecureRandom.uuid
        account_id = SecureRandom.uuid

        register_customer_in_store(customer_id, "BigCorp Ltd", store_id)
        connect_account(account_id, customer_id)
        set_login(account_id, "bigcorp@example.com")

        html = rendered_list(store_id)

        assert_includes(html, "BigCorp Ltd")
        assert_includes(html, "bigcorp@example.com")
      end

      def test_renders_create_account_link_for_customer_without_account
        store_id = SecureRandom.uuid
        customer_id = SecureRandom.uuid

        register_customer_in_store(customer_id, "MegaTron", store_id)

        html = rendered_list(store_id)
        link = Nokogiri::HTML(html).xpath('//a[text()="Create account"]').first

        assert_equal("/customers/#{customer_id}/account/new", link.attributes["href"].value)
      end

      def test_shows_only_customers_from_given_store
        store_id = SecureRandom.uuid
        other_store_id = SecureRandom.uuid
        register_customer_in_store(SecureRandom.uuid, "In Store", store_id)
        register_customer_in_store(SecureRandom.uuid, "Elsewhere", other_store_id)

        html = rendered_list(store_id)

        assert_includes(html, "In Store")
        refute_includes(html, "Elsewhere")
      end

      private

      def rendered_list(store_id)
        Customers::Rendering::CustomersList.build(CustomersController.new.view_context, store_id).to_s
      end

      def register_customer_in_store(customer_id, name, store_id)
        event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: name }))
        event_store.publish(Stores::CustomerRegistered.new(data: { customer_id: customer_id, store_id: store_id }))
      end

      def connect_account(account_id, client_id)
        event_store.publish(Authentication::AccountConnectedToClient.new(data: { account_id: account_id, client_id: client_id }))
      end

      def set_login(account_id, login)
        event_store.publish(Authentication::LoginSet.new(data: { account_id: account_id, login: login }))
      end

      def event_store
        Rails.configuration.event_store
      end
    end
  end
end
