# frozen_string_literal: true

require 'securerandom'

module Crm
  module Actions
    module Customers
      class Create < Action::Base
        include Deps['application.command_bus']

        def handle(req, res)
          params = JSON.parse(req.body.read, symbolize_names: true)
          create_customer(SecureRandom.uuid, params[:name])
        rescue Crm::Customer::AlreadyRegistered
          flash[:notice] = "Customer was already registered"
          render "new"
        else
          redirect_to customers_path, notice: "Customer was successfully created"
        end

        private

        def create_customer(customer_id, name)
          command_bus.(create_customer_cmd(customer_id, name))
        end

        def create_customer_cmd(customer_id, name)
          Crm::RegisterCustomer.new(customer_id: customer_id, name: name)
        end
      end
    end
  end
end
