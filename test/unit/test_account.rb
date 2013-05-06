require File.expand_path('../helper', File.dirname(__FILE__))

class TestAccount < ActiveSupport::TestCase
  def test_extension_loaded
    assert Account.respond_to?(:create_dummy)
  end

  def test_create_dummy
    account = Account.create_dummy

    assert account

    assert account.name?

    assert_equal true, account.valid?
    assert_equal false, account.new_record?

    assert_equal [ ], account.bills.collect(&:ids)
    assert_equal [ ], account.items.collect(&:ids)

    assert_equal account.field_a, account.field_b

    assert account.field_c?
  end
end
