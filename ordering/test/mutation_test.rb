require 'test_helper'
require 'minitest/autorun'
require 'mutant/minitest/coverage'

module Ordering
  class MutationTest < ActiveSupport::TestCase
    cover 'Ordering*'
  end
end
