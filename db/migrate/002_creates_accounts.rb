class CreatesAccounts < ActiveRecord::Migration

  def up
    create_table(:accounts) do |t|
      t.string :stream
      t.string :account_id
      t.string :name
      t.string :status
      t.string :plan
    end
    add_index :accounts, [:stream, :account_id], :uniqueness => true
  end

  def down
    delete_table(:accounts)
  end
end
