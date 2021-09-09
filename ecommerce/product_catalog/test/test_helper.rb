#require_relative '../../../rails_application/test/test_helper'

require 'active_record'
require 'minitest/autorun'
require 'mutant/minitest/coverage'
require 'arkency/command_bus'

require_relative '../../../rails_application/lib/cqrs'
require_relative '../../../lib/test_plumbing'

ApplicationRecord = Class.new(ActiveRecord::Base)

ActiveRecord::Base.establish_connection('sqlite3::memory:')
ActiveRecord::Schema.verbose = false

require_relative '../lib/product_catalog'
