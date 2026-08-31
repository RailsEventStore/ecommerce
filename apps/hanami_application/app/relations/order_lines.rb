# frozen_string_literal: true

module HanamiApplication
  module Relations
    class OrderLines < HanamiApplication::DB::Relation
      schema :order_lines, infer: true
    end
  end
end
