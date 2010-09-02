require 'helper'

class TestTestDummy < Test::Unit::TestCase
  def test_simple_model
    simple = Simple.create_fake
    
    assert_equal [ ], simple.errors.full_messages
    assert !simple.new_record?
    
    assert_equal 8, simple.name.length
  end
end
