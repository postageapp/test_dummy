class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.integer :account_id
      t.integer :bill_id
      t.string :description
      t.timestamps
    end
  end
end
