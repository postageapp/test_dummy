require File.expand_path('../helper', File.dirname(__FILE__))

class TestOperation < Test::Unit::TestCase
  def test_defaults
    loader = TestDummy::Loader.new

    assert_equal false, loader['test']
    assert_equal true, loader[Account]
  end

  def test_broken_load
    loader = TestDummy::Loader.new

    assert_equal 'NameError', loader[Broken].class.to_s
  end
end
