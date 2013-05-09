require File.expand_path('../helper', File.dirname(__FILE__))

class TestTestHelper < Test::Unit::TestCase
  def test_macros
    account = an Account

    assert account

    bill = a Bill

    assert bill

    account = an Account, :closed

    assert account
    assert account.closed_at?

    bill = a Bill, :account => account

    assert_equal account, bill.account
  end
end
