namespace :reg do
  desc "Regist new account"
  task new: :environment do
    salt = ENV["SALT"].presence
    fail "No SALT provided" unless salt
    salt.freeze
    login_pwd = ENV["LOGIN_PWD"].presence
    team = ENV["TEAM"].to_i.zero? ? nil : ENV["TEAM"].to_i
    sup = ENV["R"].to_i.zero? ? 2 : ENV["R"].to_i
    case sup
    when 1,2,3
      range = ("a"*sup.."z"*sup)
    when 4
      range = ("a".."b")
    else
      fail "Out of range. Please add R between 1 and 4"
    end
    puts "[REG][NEW]===[START]===#{Time.now}"
    range.each do |char|
      begin
        x = salt.dup.insert(-3, char)
        do_create_team(x, login_pwd, team)
      rescue => e
        Rails.logger.error("REG_ADD: #{char} | #{e}")
        next
      end
    end
    puts "[REG][NEW]===[END]=====#{Time.now}"
  end

  desc "Update main data fiels"
  task update: :environment do
    field = ENV["F"].presence
    fail "No field provided" unless field
    case field.to_sym
    when :gp_amount
      Team.registered.where(gp_amount: nil).find_each do |t|
        x = X11.new(uid: t.login_name, login_pwd: t.login_pwd)
        x.login
        x.get_gp
        puts [x.team.login_name, x.team.reload.gp_amount].inspect
      end
    when :position
    when :uid
      Team.registered.where(uid: nil, member_count: nil, league_count: nil).find_each do |t|
        x = X11.new(uid: t.login_name, login_pwd: t.login_pwd)
        x.login(on_retry: true)
        x.get_lineup
        t.reload
        puts [t.login_name, t.uid, t.member_count, t.league_count].inspect
      end
    end
  end

  private
  def do_create_team(xlogin, xpwd, xteam)
    x = X11.new(uid: xlogin, login_pwd: xpwd, tuid: xteam)
    x.register
    x.login
    x.create_team
    y = X11.new(uid: xlogin, login_pwd: xpwd, tuid: xteam)
    y.login
    y.buy_player
    z = X11.new(uid: xlogin, login_pwd: xpwd, tuid: xteam)
    z.get_lineup
    sleep 3
  end
end
