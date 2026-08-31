# frozen_string_literal: true

module HanamiApplication
  module Relations
    class Orders < HanamiApplication::DB::Relation
      schema :orders, infer: true
    end
  end
end
