class Bill < ActiveRecord::Base
  belongs_to :account
  has_many :items
end
