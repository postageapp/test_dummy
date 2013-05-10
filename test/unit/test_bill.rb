require File.expand_path('../helper', File.dirname(__FILE__))

class TestBill < Test::Unit::TestCase
  def test_extension_loaded
    assert Bill.respond_to?(:create_dummy)

    assert_equal [ :account, :order_date ], Bill.dummy_definition.fields
    assert_equal [ :account, :order_date, :due_date ], Bill.dummy_definition.fields(:overdue)
  end

  def test_create_dummy
    bill = Bill.create_dummy

    assert bill

    assert bill.order_date

    assert_equal true, bill.valid?
    assert_equal false, bill.new_record?

    assert bill.account
    assert_equal false, bill.account.new_record?

    assert_equal [ ], bill.items.collect(&:ids)
  end

  def test_create_with_account
    account = an Account
    bill = a Bill, :account => account

    assert_equal account.id, bill.account.id
  end

  def test_create_dummy_via_association
    account = an Account

    bill = one_of account.bills

    assert bill
    assert_equal true, bill.valid?
    assert_equal false, bill.new_record?

    assert_equal account.id, bill.account_id

    assert_equal [ bill.id ], account.bills.collect(&:id)
  end

  def test_with_overdue_tag
    account = an Account

    bill = Bill.create_dummy(:overdue, :account => account)

    assert bill

    assert bill.account
    assert_equal account.id, bill.account.id

    assert_equal true, bill.valid?
    assert_equal false, bill.new_record?

    assert bill.due_date

    assert_equal true, bill.overdue?

    assert_equal account.id, bill.account_id

    assert_equal [ bill.id ], account.bills.collect(&:id)
  end
end
