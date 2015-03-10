class Team < ActiveRecord::Base
  has_many :players, dependent: :destroy
  scope :valuable, -> { where("member_count >= 4") }

  def team_players
    players.where(team_uid: team_uid).grade_ordered
  end

  def league_players
    players.where(league_uid: league_uid).grade_ordered
  end

  class << self
    def regist_new(prefix)
      # do_create_team(prefix, xteam)
      ("aa".."zz").each do |char|
        begin
          x = prefix.dup.insert(-3, char)
          S11.new(x).dang_ky_team()
        rescue => e
          Rails.logger.error(e)
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
      x.buy_player
      x.get_lineup
    end
  end
end
