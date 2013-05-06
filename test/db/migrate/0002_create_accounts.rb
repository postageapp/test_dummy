class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :name
      t.string :source
      t.string :field_a
      t.string :field_b
      t.string :field_c
      t.timestamps
      t.datetime :activated_at
      t.datetime :closed_at
    end
  end
end
