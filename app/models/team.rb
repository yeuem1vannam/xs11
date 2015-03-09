class Team < ActiveRecord::Base
  has_many :players, dependent: :destroy
  scope :valuable, -> { where("member_count >= 4") }
  scope :team_players, -> {  }

  def team_players
    players.where(team_uid: team_uid)
  end

  def league_players
    players.where(league_uid: league_uid)
  end

  class << self
    def regist_new
      prefixs = {musf: 109, rmafw: 211, katafw: 204, juvfw: 411}
      # do_create_team(prefix, xteam)
      ("ca".."zz").each do |char|
        puts char
        prefixs.keys.sample(3).each do |key|
          begin
            x = key.to_s.insert(-3, char)
            puts x
            do_create_team(x, prefixs[key])
          rescue => e
            Rails.logger.error(e)
            next
          end
        end
      end
    end
    
    def update_team_lineup
      Team.where(member_count: nil, league_count: nil).find_each do |t|
        begin
          x = X11.new(uid: t.login_name, tuid: t.team_uid)
          x.login
          x.get_lineup
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
