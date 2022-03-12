# frozen_string_literal: true

require "hanami/application/routes"

module Ecommerce
  class Routes < Hanami::Application::Routes
    define do
      slice :crm, at: "/crm" do
        root to: "home.show"
      end
    end
  end
end
