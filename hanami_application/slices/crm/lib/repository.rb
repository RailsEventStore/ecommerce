# auto_register: false
# frozen_string_literal: true

require "ecommerce/repository"

module Crm
  class Repository < Ecommerce::Repository
    struct_namespace Entities
  end
end
