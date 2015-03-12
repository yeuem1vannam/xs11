class AddIndexInfoNoToPlayerInfos < ActiveRecord::Migration
  def change
    add_index :player_infos, :info_no
  end
end
