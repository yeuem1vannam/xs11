class AddPlayerInfosToPlayers < ActiveRecord::Migration
  def change
    add_reference :players, :player_info, index: true
    add_foreign_key :players, :player_infos
  end
end
