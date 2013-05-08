require  File.expand_path('../helper', File.dirname(__FILE__))

require 'example'

class TestTestDummy < Test::Unit::TestCase
  def test_example_model
    example = Example.create_dummy
    
    assert_equal Example, example.class
    
    assert_equal [ ], example.errors.full_messages
    assert !example.new_record?
    
    assert example.name
    assert_equal 8, example.name.length
  end

  def test_extensions
    assert_equal true, respond_to?(:a)
    assert_equal true, respond_to?(:an)
    assert_equal true, respond_to?(:one_of)
  end
end
