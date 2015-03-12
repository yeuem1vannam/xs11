class PlayerInfo < ActiveRecord::Base
  serialize :info, Hash
  validates :info_no, uniqueness: true, presence: true

  def migrate_to_player
    Player.connection.execute("UPDATE `players` SET `players`.`player_info_id` = #{id} WHERE `players`.`uid` = #{info_no}")
  end
end
