require "test_helper"

class ResultTest < InMemoryTestCase
  cover Result

  def test_executes_path
    result = Result.new(:first_path)
    executed_path = nil

    result.path(:first_path) { executed_path = :first }
    result.path(:other_path) { executed_path = :other }

    assert_equal :first, executed_path
  end

  def test_executes_path_with_argument
    result = Result.new(:first_path, "argument")
    executed_path = nil

    result.path(:first_path) do |arg|
      assert arg == "argument"

      executed_path = :first
    end
    result.path(:other_path) { |_arg| executed_path = :other }

    assert_equal :first, executed_path
  end

  def test_executes_path_with_multiple_arguments
    result = Result.new(:first_path, "argument1", "argument2")
    executed_path = nil

    result.path(:first_path) do |arg1, arg2|
      assert arg1 == "argument1"
      assert arg2 == "argument2"

      executed_path = :first
    end
    result.path(:other_path) { |_arg| executed_path = :other }

    assert_equal :first, executed_path
  end
end
