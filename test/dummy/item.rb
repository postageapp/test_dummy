class Item
  # The bill is associated with an account, so this item should copy that
  # relationship if one is not explicitly defined. This is done by requesting
  # that the `account` attribute is inherited from bill.account if defined.
  dummy :account,
    :from => 'bill.account'

  # The bill is associated with an account, so this item should copy that
  # relationship if one is not explicitly defined. This is done by requesting
  # that the `account_id` attribute is inherited from account.id if defined.
  dummy :bill,
    :inherit => {
      :account_id => [ :account, :id ]
    }

  dummy :description
end
