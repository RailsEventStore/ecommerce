# frozen_string_literal: true

require "billy/capybara/rspec"
require "logger"

Billy.configure do |config|
  config.cache = true
  config.persist_cache = true
  config.cache_path = SPEC_ROOT.join("../tmp/billy_requests")
  config.logger = Logger.new(SPEC_ROOT.join("../log/billy.log"))
  config.ignore_params = []

  # Uncomment to access `Billy.proxy.requests`
  # config.record_requests = true
end
