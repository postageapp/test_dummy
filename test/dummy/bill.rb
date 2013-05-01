class Bill
  dummy :account

  dummy :order_date do
    Date.today.advance(:days => rand(-2000))
  end
end
