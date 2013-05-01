class Account < ActiveRecord::Base
  attr_accessible :name

  validates :name,
    :presence => true

  has_many :bills
  has_many :items,
    :through => :bills
end
