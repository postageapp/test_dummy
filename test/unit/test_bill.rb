require File.expand_path('../helper', File.dirname(__FILE__))

class TestBill < ActiveSupport::TestCase
  def test_extension_loaded
    assert Bill.respond_to?(:create_dummy)
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

  def test_create_dummy_via_association
    account = an Account

    bill = one_of account.bills

    assert bill
    assert_equal true, bill.valid?
    assert_equal false, bill.new_record?

    assert_equal account.id, bill.account_id

    assert_equal [ bill.id ], account.bills.collect(&:id)
  end
end
