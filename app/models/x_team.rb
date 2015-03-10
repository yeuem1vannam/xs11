class XTeam < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["#{Rails.env}_sqlite"].present? ? "#{Rails.env}_sqlite".to_sym : "#{Rails.env}".to_sym
  self.table_name = "teams"
  has_many :players, dependent: :destroy, foreign_key: :team_id, class_name: XPlayer.name
  after_commit :sync_to_main

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

  private
  def sync_to_main
    if Rails.configuration.database_configuration["#{Rails.env}"]["adapter"] == "mysql2"
      self.to_main_data
    end
  end

  class << self
    def regist_new(prefix, xteam = nil)
      ("aa".."zz").each do |char|
        begin
          x = prefix.dup.insert(-3, char)
          do_create_team(x, xteam)
        rescue => e
          Rails.logger.error("REGIST_NEW: #{e}")
          next
        end
      end
    end

    private
    def do_create_team(xlogin, xteam)
      x = X11.new(uid: xlogin, tuid: xteam)
      x.register
      x.login
      x.create_team
      y = X11.new(uid: xlogin, tuid: xteam)
      y.login
      y.buy_player
      z = X11.new(uid: xlogin, tuid: xteam)
      z.get_lineup
      sleep 3
    end
  end
end
