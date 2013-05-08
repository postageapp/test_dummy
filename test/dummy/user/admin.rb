class User::Admin
  dummy :authorization_code do
    '%04d' % SecureRandom.random_number(1000)
  end
end
