command_bus = Rails.configuration.command_bus

[
  "Alice Johnson",
  "Bob Smith",
  "Carol White"
].each do |name|
  command_bus.call(Crm::RegisterContact.new(contact_id: SecureRandom.uuid, name: name))
end

companies = {
  "Arkency" => "https://linkedin.com/company/arkency",
  "Basecamp" => "https://linkedin.com/company/basecamp",
  "Shopify" => nil
}
companies.each do |name, linkedin_url|
  company_id = SecureRandom.uuid
  command_bus.call(Crm::RegisterCompany.new(company_id: company_id, name: name))
  command_bus.call(Crm::SetCompanyLinkedinUrl.new(company_id: company_id, linkedin_url: linkedin_url)) if linkedin_url
end

pipeline_id = SecureRandom.uuid
command_bus.call(Crm::CreatePipeline.new(pipeline_id: pipeline_id, name: "Sales"))
["Lead", "Qualification", "Proposal", "Negotiation", "Closed Won"].each do |stage|
  command_bus.call(Crm::AddStageToPipeline.new(pipeline_id: pipeline_id, stage_name: stage))
end

[
  ["Arkency consulting deal", 50_000, "2026-06-01", "Proposal"],
  ["Basecamp migration", 120_000, "2026-09-15", "Lead"],
  ["Shopify integration", 30_000, "2026-04-01", "Negotiation"]
].each do |name, value, close_date, stage|
  deal_id = SecureRandom.uuid
  command_bus.call(Crm::CreateDeal.new(deal_id: deal_id, pipeline_id: pipeline_id, name: name))
  command_bus.call(Crm::SetDealValue.new(deal_id: deal_id, value: value))
  command_bus.call(Crm::SetDealExpectedCloseDate.new(deal_id: deal_id, expected_close_date: close_date))
  command_bus.call(Crm::MoveDealToStage.new(deal_id: deal_id, stage: stage))
end
