require 'test_helper'
path = Rails.root.join('../ecommerce/product_catalog/test')

Dir.glob("#{path}/**/*_test.rb") do |file|
  require file
end
