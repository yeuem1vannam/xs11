class XTeam < ActiveRecord::Base
  establish_connection :development_sqlite
  self.table_name = "teams"
  has_many :players, dependent: :destroy, foreign_key: :team_id, class_name: XPlayer.name

  def to_main_data
    team = Team.where(login_name: login_name).first_or_create
    team.update(self.attributes.except("id"))
    ActiveRecord::Base.transaction do
      players.find_each do |p|
        player = team.players.where(uid: p.uid).first_or_create
        player.update!(p.attributes.except("id").merge("team_id" => team.id))
      end
    end
  end
end
