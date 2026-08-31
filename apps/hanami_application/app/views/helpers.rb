# auto_register: false
# frozen_string_literal: true

module HanamiApplication
  module Views
    module Helpers
      def format_price(amount)
        format("$%.2f", amount)
      end
    end
  end
end
