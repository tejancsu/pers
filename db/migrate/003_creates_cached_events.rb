class CreatesCachedEvents < ActiveRecord::Migration

  def up
    create_table(:cached_events) do |t|
      t.string :stream
      t.string :user_id
      t.string :account_id
      t.string :date
      t.string :event
    end
    add_index :cached_events, [:stream, :user_id], :uniqueness => true
  end

  def down
    delete_table(:cached_events)
  end
end
