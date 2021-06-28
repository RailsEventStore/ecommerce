require 'test_helper'
path = Rails.root.join('crm/test')

Dir.glob("#{path}/**/*_test.rb") do |file|
  require file
end
