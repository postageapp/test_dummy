require File.expand_path('../helper', File.dirname(__FILE__))

class TestDefinition < Test::Unit::TestCase
  def test_reflection_properties
    class_name, foreign_key = TestDummy::Support.reflection_properties(Bill, :account)

    assert_equal Account, class_name
    assert_equal :account_id, foreign_key
  end
end
