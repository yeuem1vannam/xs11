class CreatePlayerInfo < ActiveRecord::Migration
  def change
    create_table :player_infos do |t|
      t.text :info
      t.integer :info_no
    end
  end
end
