require_relative '../helper'

class TestAccount < Test::Unit::TestCase
  def test_extension_loaded
    assert Account.respond_to?(:create_dummy)

    assert TestDummy::Loader.load!(Account)

    assert_equal [ :name, :field_a, :field_b, :activated_at ], Account.dummy_definition.fields
  end

  def test_create_dummy
    account = Account.create_dummy

    assert account

    assert account.name?

    assert_equal 'dummy', account.source

    assert_equal true, account.valid?
    assert_equal false, account.new_record?

    assert_equal [ ], account.bills.collect(&:ids)
    assert_equal [ ], account.items.collect(&:ids)

    assert_equal account.field_a, account.field_b

    assert account.field_c?

    assert account.activated_at?
    assert !account.closed_at?
  end

  def test_create_dummy_unactivated
    account = Account.create_dummy(:unactivated)

    assert account

    assert account.name?

    assert_equal true, account.valid?
    assert_equal false, account.new_record?

    assert_equal [ ], account.bills.collect(&:ids)
    assert_equal [ ], account.items.collect(&:ids)

    assert_equal account.field_a, account.field_b

    assert account.field_c?

    assert !account.activated_at?
    assert !account.closed_at?
  end

  def test_create_dummy_closed
    account = Account.create_dummy(:closed)

    assert account

    assert account.name?

    assert_equal true, account.valid?
    assert_equal false, account.new_record?

    assert_equal [ ], account.bills.collect(&:ids)
    assert_equal [ ], account.items.collect(&:ids)

    assert_equal account.field_a, account.field_b

    assert !account.field_c?

    assert account.activated_at?
    assert account.closed_at?
  end

  def test_create_dummy_closed_and_unactivated
    account = Account.create_dummy(:closed, :unactivated)

    assert account

    assert account.name?

    assert_equal true, account.valid?
    assert_equal false, account.new_record?

    assert_equal [ ], account.bills.collect(&:ids)
    assert_equal [ ], account.items.collect(&:ids)

    assert_equal account.field_a, account.field_b

    assert !account.field_c?

    assert !account.activated_at?
    assert account.closed_at?
  end
end
