# auto_register: false
# frozen_string_literal: true

require "ecommerce/repository"

module Main
  class Repository < Ecommerce::Repository
    struct_namespace Entities
  end
end
