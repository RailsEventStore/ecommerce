module Crm
  class RegisterContact
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :contact_id, :name
    alias aggregate_id contact_id

    def initialize(contact_id, name)
      @contact_id = contact_id
      @name = name
      valid = @contact_id.is_a?(String) && UUID.match?(@contact_id) && @name.is_a?(String)
      raise Infra::Command::Invalid unless valid
    end
  end
end
