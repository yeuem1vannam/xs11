class Team < ActiveRecord::Base
  has_many :players, dependent: :destroy
<<<<<<< HEAD
  scope :registered, -> { where(registered: true) }
  scope :not_registered, -> { where.not(registered: true) }
  scope :valuable, -> { registered.where("member_count >= 4") }

  def team_players
    players.where(team_uid: team_uid).grade_ordered
  end

  def league_players
    players.where(league_uid: league_uid).grade_ordered
  end

  def team_form
    return @team_form if @team_form
    team_players.where(position: nil).find_each(&:possible_position)
    x = team_players.to_a
    xform = {}
    Player::POS.sort { |x, y| x[1] <=> y[1] }.each do |pos, val|
      next if ["CAM", "LM", "RM"].include?(pos)
      c = ["CB", "CM"].include?(pos) ? 2 : 1
      xp = x.select { |p| val & p.position != 0}.sort { |a, b| a.position <=> b.position }.first(c)
      if xp
        xform[pos] = [*xp][0...c]
        [*xp][0...c].each { |xxp| x.delete xxp }
      end
    end
    @team_form = {in_form: xform, other: x}
    @team_form
  end

=======
  scope :valuable, -> { where("member_count >= 4") }
>>>>>>> #1
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
