require File.expand_path('../helper', File.dirname(__FILE__))

class TestDefinition < Test::Unit::TestCase
  def test_defaults
    definition = TestDummy::Definition.new

    assert_equal [ ], definition.can_dummy_fields
    assert_equal false, definition.can_dummy?(nil)
  end

  def test_define_operation_on_reflection
    definition = TestDummy::Definition.new

    definition.define_operation(Bill, [ :account ], { })

    assert_equal [ :account ], definition.can_dummy_fields
  end
end
