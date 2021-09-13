module Crm
  class Customer < ActiveRecord::Base
    AlreadyRegistered = Class.new(StandardError)

    def register(name)
      raise AlreadyRegistered unless new_record?
      self.name = name
    end
  end
end