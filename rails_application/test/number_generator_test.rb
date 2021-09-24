require "test_helper"
require "number_generator"

class NumberGeneratorTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def test_happy_path
    this_month = Time.new(2021, 9)
    number_generator = NumberGenerator.new(->{ this_month })
    number_generator.reset

    assert_equal "2021/09/1", number_generator.call
    assert_equal "2021/09/2", number_generator.call
    assert_equal "2021/09/3", number_generator.call
  end

   def test_concurrent_generation
     this_month = Time.new(2021, 9)
     number_generator = NumberGenerator.new(->{ this_month })
     number_generator.reset

     concurrency_level = 4
     assert ActiveRecord::Base.connection.pool.size > concurrency_level

     wait_for_it = true
     threads = concurrency_level.times.map do |i|
       Thread.new do
         true while wait_for_it
         number_generator.call
       end
     end
     wait_for_it = false
     threads.each(&:join)

     assert_equal "2021/09/5", number_generator.call
   end
end