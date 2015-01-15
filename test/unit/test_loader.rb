require_relative '../helper'

class TestOperation < MiniTest::Test
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
