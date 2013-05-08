class User
  dummy :name,
    :with => :random_string

  dummy [ :password, :password_confirmation ] do
    TestDummy::Helper.random_phonetic_string
  end
end
