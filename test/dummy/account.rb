class Account
  # Populate the name attribute unless already defined.
  dummy :name do
    TestDummy::Helper.random_string(8)
  end

  # Runs unconditionally on every dummy object created.
  dummy do |account|
    account.source = 'dummy'
  end

  dummy [ :field_a, :field_b ] do
    TestDummy::Helper.random_string(8)
  end

  dummy except: :closed do |m|
    m.field_c = TestDummy::Helper.random_string(8)
  end

  dummy :activated_at, except: :unactivated do
    Time.now - rand(86400 * 365) - 86400
  end

  dummy :closed_at, only: [ :closed ] do |m|
    (m.activated_at || Time.now) + rand(86400)
  end
end
