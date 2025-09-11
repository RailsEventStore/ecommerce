# require_with_metadata: true
# frozen_string_literal: true

require "capybara/cuprite"
require "capybara/rspec"
require "capybara-screenshot/rspec"
require "rack"
require "rack/test"

Dir[SPEC_ROOT.join("support/web/*.rb").to_s].each(&method(:require))

Capybara.app = Rack::Builder.parse_file(SPEC_ROOT.join("../config.ru").realpath.to_s).first
Capybara.server = :puma, {Silent: true}
Capybara.server_port = 3001
Capybara.test_id = "data-test"
Capybara.default_max_wait_time = 5
Capybara.save_path = Test::Suite.instance.tmp_dir.join("capybara-screenshot").to_s
Capybara.javascript_driver = :cuprite

Capybara.register_driver :cuprite do |app|
  browser_options =
    if RSpec.configuration.filter.rules[:full_integration]
      {}
    else
      {
        "ignore-certificate-errors" => nil,
        "proxy-server" => "#{Billy.proxy.host}:#{Billy.proxy.port}",
        "proxy-bypass-list" => "127.0.0.1;localhost"
      }
    end

  Capybara::Cuprite::Driver.new(
    app,
    browser_options: browser_options,
    # headless: false,
    js_errors: false,
    # logger: $stderr,
    # slowmo: 0.5,
    window_size: [1600, 1600]
  )
end

Capybara::Screenshot.register_driver(:cuprite, &Capybara::Screenshot.registered_drivers[:default])
Capybara::Screenshot.prune_strategy = {keep: 10}

RSpec.configure do |config|
  config.include Capybara::DSL, Capybara::RSpecMatchers, :web
  config.include Test::Web::Helpers, :web
end
