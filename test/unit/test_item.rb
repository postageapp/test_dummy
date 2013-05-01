require File.expand_path('../helper', File.dirname(__FILE__))

class TestItem < ActiveSupport::TestCase
  def test_extension_loaded
    assert Item.respond_to?(:create_dummy)
  end

  def test_reflection_properties
    reflection_class, foreign_key = TestDummy::Support.reflection_properties(Item, :account)

    assert_equal Account, reflection_class
    assert_equal :account_id, foreign_key
  end

  def test_create_dummy
    item = Item.create_dummy

    assert item

    assert item.description?

    assert_equal true, item.valid?
    assert_equal false, item.new_record?

    assert item.account
    assert_equal false, item.account.new_record?
    assert_equal item.account.id, item.account_id

    assert item.bill
    assert_equal false, item.bill.new_record?
    assert_equal item.bill.id, item.bill_id
    assert_equal item.account.id, item.bill.account_id

    assert_equal [ item.id ], item.account.items.collect(&:id)
    assert_equal [ item.id ], item.bill.items.collect(&:id)
  end

  def test_create_dummy_via_association
    bill = a Bill

    assert_equal false, bill.new_record?

    item = one_of bill.items

    assert item
    assert_equal true, item.valid?
    assert_equal false, item.new_record?

    assert_equal bill.id, item.bill_id

    assert_equal bill.account_id, item.account_id

    account = bill.account

    assert_equal [ bill.id ], account.bills.collect(&:id)
    assert_equal [ item.id ], account.items.collect(&:id)
  end
end
