require File.expand_path('../helper', File.dirname(__FILE__))

class TestUser < MiniTest::Unit::TestCase
  def test_extension_loaded
    assert User.respond_to?(:create_dummy)

    assert TestDummy::Loader.load!(User)
  end

  def test_create_dummy
    user = User.create_dummy

    assert user

    assert user.name?
    assert user.password_crypt?
  end
end
