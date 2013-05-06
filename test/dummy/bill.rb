class Bill
  dummy :account

  dummy :order_date do
    Date.today.advance(:days => rand(-365))
  end

  dummy :due_date, :only => :overdue do |bill|
    date = bill.order_date.advance(:days => 90)

    (date >= Date.today) ? Date.today.advance(:days => -1) : date
  end
end
