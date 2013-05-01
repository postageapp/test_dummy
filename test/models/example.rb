class Example < ActiveRecord::Base
  dummy :name do
    TestDummy::Helper.random_string(8)
  end
end
