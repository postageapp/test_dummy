class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :type
      t.integer :account_id
      t.string :name
      t.string :password_crypt
      t.string :authorization_code
      t.timestamps
    end
  end
end
