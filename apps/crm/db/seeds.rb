command_bus = Rails.configuration.command_bus

[
  "Alice Johnson",
  "Bob Smith",
  "Carol White"
].each do |name|
  command_bus.call(Crm::RegisterContact.new(SecureRandom.uuid, name))
end

companies = {
  "Arkency" => "https://linkedin.com/company/arkency",
  "Basecamp" => "https://linkedin.com/company/basecamp",
  "Shopify" => nil
}
companies.each do |name, linkedin_url|
  company_id = SecureRandom.uuid
  command_bus.call(Crm::RegisterCompany.new(company_id, name))
  command_bus.call(Crm::SetCompanyLinkedinUrl.new(company_id, linkedin_url)) if linkedin_url
end

pipeline_id = SecureRandom.uuid
command_bus.call(Crm::CreatePipeline.new(pipeline_id, "Sales"))
["Lead", "Qualification", "Proposal", "Negotiation", "Closed Won"].each do |stage|
  command_bus.call(Crm::AddStageToPipeline.new(pipeline_id, stage))
end

[
  ["Arkency consulting deal", 50_000, "2026-06-01", "Proposal"],
  ["Basecamp migration", 120_000, "2026-09-15", "Lead"],
  ["Shopify integration", 30_000, "2026-04-01", "Negotiation"]
].each do |name, value, close_date, stage|
  deal_id = SecureRandom.uuid
  command_bus.call(Crm::CreateDeal.new(deal_id, pipeline_id, name))
  command_bus.call(Crm::SetDealValue.new(deal_id, value))
  command_bus.call(Crm::SetDealExpectedCloseDate.new(deal_id, close_date))
  command_bus.call(Crm::MoveDealToStage.new(deal_id, stage))
end
