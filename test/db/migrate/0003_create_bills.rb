class CreateBills < ActiveRecord::Migration
  def change
    create_table :bills do |t|
      t.integer :account_id
      t.date :order_date
      t.timestamps
    end
  end
end
