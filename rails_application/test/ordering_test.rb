require 'test_helper'
path = Rails.root.join('../ecommerce/ordering/test')

Dir.glob("#{path}/**/*_test.rb") do |file|
  require file
end
