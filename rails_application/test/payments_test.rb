require 'test_helper'
path = Rails.root.join('ecommerce/payments/test')

Dir.glob("#{path}/**/*_test.rb") do |file|
  require file
end
