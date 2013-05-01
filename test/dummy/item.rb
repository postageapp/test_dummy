class Item
  dummy :account,
    :from => 'bill.account'

  dummy :bill,
    :inherit => {
      :account_id => [ :account, :id ]
    }

  dummy :description
end
