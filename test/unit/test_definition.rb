require_relative '../helper'

class TestDefinition < MiniTest::Test
  def test_defaults
    definition = TestDummy::Definition.new

    assert_equal [ ], definition.fields
    assert_equal true, definition.fields?(nil)
    assert_equal false, definition.fields?([ :field ])
  end

  def test_define_operation_on_reflection
    definition = TestDummy::Definition.new

    definition.define_operation(Bill, [ :account ], { })

    assert_equal [ :account ], definition.fields
    assert_equal true, definition.fields?(:account)
    assert_equal false, definition.fields?(:invalid)
    assert_equal false, definition.fields?([ :invalid, :account ])
  end

  def test_define_operation_with_options
    definition = TestDummy::Definition.new

    triggered = 0

    options = {
      :only => [ :only_tag ].freeze,
      :except => [ :except_tag ].freeze,
      :block => lambda { triggered += 1 }
    }.freeze

    definition.define_operation(Bill, [ :account ], options)

    assert_equal [ :account ], definition.fields([ :only_tag ])
  end

  def test_apply_with_after_option
    definition = TestDummy::Definition.new

    triggered = 0

    options = {
      :after => :save,
      :block => lambda { triggered += 1 }
    }.freeze

    definition.define_operation(Bill, [ :account ], options)

    definition.apply!(nil, { }, [ ])

    assert_equal 0, triggered

    definition.apply_after_save!(nil, { }, [ ])

    assert_equal 1, triggered
  end
end
