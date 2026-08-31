# frozen_string_literal: true

module HanamiApplication
  module Relations
    class Products < HanamiApplication::DB::Relation
      schema :products, infer: true
    end
  end
end
