require File.expand_path('../helper', File.dirname(__FILE__))

class TestOperation < MiniTest::Unit::TestCase
  def test_defaults
    loader = TestDummy::Loader.new

    assert_equal false, loader['test']
    assert_equal true, loader[Account]
  end

  def test_broken_load
    exception = nil
    loader = TestDummy::Loader.new

    begin
      loader[Broken]
    rescue NameError => e
      exception = e
    end

    assert_equal 'NameError', exception.class.to_s
  end
end
