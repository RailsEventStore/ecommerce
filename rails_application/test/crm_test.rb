require 'test_helper'
path = Rails.root.join('../ecommerce/crm/test')

Dir.glob("#{path}/**/*_test.rb") do |file|
  require file
end
