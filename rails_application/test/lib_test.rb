require "test_helper"
path = Rails.root.join("lib")

Dir.glob("#{path}/**/*_test.rb") do |file|
  require file
end
