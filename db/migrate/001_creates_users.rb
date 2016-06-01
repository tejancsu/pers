class CreatesUsers < ActiveRecord::Migration

  def up
    create_table(:users) do |t|
      t.string :stream
      t.string :user_id
      t.string :name
      t.string :role
      t.string :account_id
    end

    add_index :users, [:stream, :user_id], :uniqueness => true
  end

  def down
    delete_table(:users)
  end
end
