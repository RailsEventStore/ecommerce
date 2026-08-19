require "test_helper"

module ClientOrders
  module Rendering
    class FreeProductSavingRendererTest < ActiveSupport::TestCase
      cover "ClientOrders::Rendering::FreeProductSaving"

      def test_renders_safe_table_cells
        assert(rendered.html_safe?)
        assert_equal(
          %(<td class="py-2" colspan="4">3+1 — cheapest item free</td>\n<td class="py-2">-$10.00</td>),
          rendered
        )
      end

      private

      def rendered
        @rendered ||= FreeProductSaving.new.call(10)
      end
    end
  end
end
