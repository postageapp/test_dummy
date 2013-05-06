class Bill < ActiveRecord::Base
  belongs_to :account
  has_many :items

  def overdue?
    return false unless (self.due_date)
    
    Date.today >= self.due_date
  end
end
