require "database_cleaner/sequel"
require_relative "helpers"

DatabaseCleaner[:sequel].strategy = :transaction

RSpec.configure do |config|
  config.before :suite do
    DatabaseCleaner[:sequel].clean_with :truncation
  end

  config.prepend_before :each, :db do |example|
    strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner[:sequel].strategy = strategy

    DatabaseCleaner[:sequel].start
  end

  config.append_after :each, :db do
    DatabaseCleaner[:sequel].clean
  end
end
