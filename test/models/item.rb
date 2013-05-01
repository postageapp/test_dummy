class Item < ActiveRecord::Base
  belongs_to :account
  belongs_to :bill
end
