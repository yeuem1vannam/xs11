require "agent"
class X11
  TUIDS = [819, 411, 107, 211, 204, 109]
  attr_accessor :agent, :login_name, :password, :team, :team_uid
  def initialize(uid: nil, pwd: nil, tuid: nil)
    options = {
      open_timeout: 3,
      read_timeout: 4,
      keep_alive: true,
      redirect_ok: true,
    }
    @memo = Logger.new("log/memo.log")
    @choose = Logger.new("log/choose.log")
    @agent = Mechanize.new do |a|
      a.log = Logger.new("log/s11.log")
      a.user_agent_alias = "Linux Firefox"
      a.open_timeout = options[:open_timeout]
      a.read_timeout = options[:read_timeout]
      a.keep_alive = options[:keep_alive]
      a.redirect_ok = options[:redirect_ok]
    end
    @login_name = uid
    @password = pwd || 1
    unless uid
      raise "Missing arguments: Username: #{uid} / team_uid: #{tuid}"
    end
    @team = XTeam.where(login_name: uid).first_or_create
    unless @team.team_uid
      @team.update(team_uid: tuid || TUIDS.sample)
    end
    @team_uid = @team.team_uid
    @agent.cookie_jar.load(agent_cookie) if logged_in?
  end

  def register
    @agent.get("http://s11.sgame.vn")
    sleep 1
    url = "http://s11.sgame.vn/ajax/dkn"
    params = {
      txt_username: login_name,
      txt_password: password,
      re_txt_password: password,
      a: nil,
      c: nil,
      partner_id: nil,
      url: "/"
    }
    request = @agent.post(url, params)
    dkn_body = JSON.parse request.body
    Rails.logger.info("REGISTER_MSG: #{dkn_body['msg']}")
    if dkn_body["err"].zero?
      return self.login
    end
  rescue => e
    Rails.logger.error("REGISTER: #{e}")
  end

  def login(on_retry: false)
    if logged_in? && !on_retry
      puts "Logged in. Load from cookie"
      return true
    else
      login = {
        username: login_name,
        password: password,
        url: "http://s11.sgame.vn/play"
      }
      if on_retry && logged_in?
        File.delete(agent_cookie)
      end
      login_page = @agent.post("http://s11.sgame.vn/ajax/login", login)
      login_page = JSON.parse(login_page.body)
      Rails.logger.info("LOGIN_MSG: #{login_page['msg']}")
      if login_page["err"] == 0
        puts login_page["msg"]
        @agent.get("http://s11.sgame.vn/play")
        @agent.get("http://s11.sgame.vn/gmc/main")
        @agent.cookie_jar.save_as(agent_cookie)
        return true
      else
        return false
      end
    end
  rescue => e
    Rails.logger.error("LOGIN: #{e}")
    puts "Retry login"
    unless on_retry
      self.login(on_retry: true)
    end
  end

  def create_team
    @agent.get("http://play.s11.sgame.vn/foundation/create")
    sleep 1
    teamname = teamint = nil
    while !teamname
      teamname = (0...6).map { ([*0..9] + [*'A'..'Z'])[rand(36)] }.join
      teamint = teamname.scan(/[A-Z]/).first(3).join
      if teamint.length < 3
        teamint << (0...(3 - teamint.length)).map { [*"A".."Z"][rand(26)] }.join
      end
      check1 = @agent.post("http://play.s11.sgame.vn/foundation/team/duplicated", {name: teamname}).body
      check2 = @agent.post("http://play.s11.sgame.vn/foundation/coach/duplicated", {name: teamname}).body
      if check1 == "true" || check2 == "true"
        teamname = nil
      end
    end
    puts [login_name, teamname, teamint].inspect
    params = {
      json: '{"teamName":"%s","teamInitials":"%s","coachName":"%s","motherTeam":%s,"players":%s,"natNo":0,"squadName":"XXX"}' % [teamname, teamint, teamname, target[:team_uid], target[:main].inspect],
      path: "PC"
    }
    z = @agent.post("http://play.s11.sgame.vn/foundation/create2", params)
    z = JSON.parse(z.body)
    Rails.logger.info("CREATE_TEAM_MSG: #{z['msg']}")
    if z["code"]
      puts z["msg"]
      return z["code"] == "SUCCESS"
    end
  rescue => e
    Rails.logger.error("CREATE_TEAM: #{e}")
  end

  def buy_player
    succ = []
    err = []
    thread_no = target[:pre] ? 20 : 200
    Parallel.each((1..thread_no).to_a, in_threads: (target[:pre] ? 0 : thread_no)) do
      begin
        b = @agent.post("http://play.s11.sgame.vn/shop/buy", buy_params, {"Referer" => "http://play.s11.sgame.vn/gmc/main"})
        b = JSON.parse(b.body)
        profile = b["result"]["openItemMap"]["appliedList"].first["playerInventory"]["playerProfile"]
        if profile["mteamNo"] == target[:team_uid]
          succ.push(profile["plrName"])
        end
      rescue => e
        err.push(e)
      end
    end
    Rails.logger.info("BUY_PLAYER_SUCC: #{succ.join('-')}")
  rescue => e
    Rails.logger.error("BUY_PLAYER: #{e}")
  end

  def get_lineup
    if self.login
      parse_lineup()
    else
      raise "Login failed"
    end
  end

  private
  def agent_cookie
    "tmp/#{login_name}.cookie"
  end

  def logged_in?
    File.exists?(agent_cookie)
  end

  def parse_lineup
    lineup = "http://play.s11.sgame.vn/gmc/squad/lineup?debug=N&_=#{Time.now}"
    data = @agent.get(lineup)
    cdata = data.search("script").last.text
    cdata.strip!
    adata = cdata.split("\n").first
    adata.gsub!("var _ghtTmp = ", "")
    adata.strip!
    adata[-1] = ""
    jdata = JSON.parse(adata)
    ActiveRecord::Base.transaction do
      jdata["players"].each do |j|
        player = @team.players.where(
          uid: j["playerInventory"]["playerProfile"]["plrProfileInfoNo"],
          league_uid: j["playerInventory"]["playerProfile"]["mleagNo"],
          team_uid: j["playerInventory"]["playerProfile"]["mteamNo"],
          name: j["playerInventory"]["playerProfile"]["plrName"],
          grade: j["playerInventory"]["grd"]
          ).first_or_create
        player.update!(info: j["playerInventory"])
      end
    end
    @team.update!(
      uid: jdata["squad"]["teamNo"],
      league_uid: target[:league_uid],
      member_count: @team.players.where(team_uid: target[:team_uid]).count,
      league_count: @team.players.where(league_uid: target[:league_uid]).count,
      team_uid: target[:team_uid]
    )
  end

  def target
    if @target
      @target
    else
      result = {team_uid: team_uid}
      case team_uid
      when 819
        result[:main] = [819140171,819140121,819140181]
        result[:league_uid] = 8
        result[:pre] = false
      when 411
        # Juve
        result[:main] = [411140191,411140171,411140071]
        result[:league_uid] = 4
        result[:pre] = true
      when 107
        # Live
        result[:main] = [107140191,107140281,107140241]
        result[:league_uid] = 1
        result[:pre] = true
      when 211
        # Real
        result[:main] = [211140211,211140181,211140141]
        result[:league_uid] = 2
        result[:pre] = true
      when 204
        # Barca
        result[:main] = [204140141,204140171,204140121]
        result[:league_uid] = 2
        result[:pre] = true
      when 109
        # MU
        result[:main] = [109140301,109140141,109140111]
        result[:league_uid] = 1
        result[:pre] = true
      end
      @target = result
      return @target
    end
  end

  def buy_params
    @buy_params ||= {
      productId: target[:pre] ? "prplr_premium_lv1" : "prplr_basic_lv1",
      buyCount: 1
    }
  end
end
