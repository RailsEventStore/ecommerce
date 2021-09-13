require "minitest/autorun"
require "mutant/minitest/coverage"

require "active_record"
ActiveRecord::Base.establish_connection("sqlite3::memory:")
ActiveRecord::Schema.verbose = false

require_relative "../lib/product_catalog"
