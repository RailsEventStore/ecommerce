module Crm
  class SetCompanyLinkedinUrl
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :company_id, :linkedin_url
    alias aggregate_id company_id

    def initialize(company_id, linkedin_url)
      @company_id = company_id
      @linkedin_url = linkedin_url
      valid = @company_id.is_a?(String) && UUID.match?(@company_id) && @linkedin_url.is_a?(String)
      raise Infra::Command::Invalid unless valid
    end
  end
end
