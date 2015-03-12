class AddIndexUidToPlayers < ActiveRecord::Migration
  def change
    add_index :players, :uid
  end
end
