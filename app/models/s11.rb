require 'agent'

class S11
  attr_accessor :agent, :memo, :username, :dkn_flag, :err
  x = 4
  pre = true
  result = {target: nil, main: nil, league: nil}
  case x
  when 1
    # bo dao nha
    result[:target] = 819
    result[:main] = [819140171,819140121,819140181]
    result[:league] = 8
    pre = false
  when 2
    # Juve
    result[:target] = 411
    result[:main] = [411140191,411140171,411140071]
    result[:league] = 4
    pre = true
  when 3
    # Live
    result[:target] = 107
    result[:main] = [107140191,107140281,107140241]
    result[:league] = 1
    pre = true
  when 4
    # Real
    result[:target] = 211
    result[:main] = [211140211,211140181,211140141]
    result[:league] = 2
    pre = true
  when 5
    # Barca
    result[:target] = 204
    result[:main] = [204140141,204140171,204140121]
    result[:league] = 2
    pre = true
  when 6
    # MU
    result[:target] = 109
    result[:main] = [109140301,109140141,109140111]
    result[:league] = 1
    pre = true
  end
  # 819 Bo dao nha
  # TARGET = 819
  # MAIN = [819140171,819140121,819140181]
  # 411: Juve
  # [411140191,411140171,411140071] Pirlo / Marchisio / Barzagli
  # 107: Live
  # [107140191,107140281,107140241] Gerrard / Lambert / Sterring
  # 211: Madrid
  # [211140211,211140181,211140141] Ronaldo / Isco / Illara
  # 204: Barca
  # [204140141,204140171,204140121] Xavi / Iniesta / Busquet (15: Rakitik)
  TARGET = result[:target]
  MAIN = result[:main]
  LEAGUE = result[:league]
  BUY = {productId: pre ? "prplr_premium_lv1" : "prplr_basic_lv1", buyCount: 1} #prplr_premium_lv1 / prplr_basic_lv1
  T_NO = pre ? 20 : 200
  SLEE1 = pre ? 2 : 15
  SLEE2 = pre ? 2 : 5
  def initialize(usrname = nil, flag = false, xerr = false)
    options = {
      open_timeout: 3,
      read_timeout: 4,
      keep_alive: true,
      redirect_ok: true,
    }
    @memo = Logger.new("memo.log")
    @choose = Logger.new("choose.log")
    @agent = Mechanize.new do |a|
      a.log = Logger.new("s11.log")
      a.user_agent_alias = "Linux Firefox"
      a.open_timeout = options[:open_timeout]
      a.read_timeout = options[:read_timeout]
      a.keep_alive = options[:keep_alive]
      a.redirect_ok = options[:redirect_ok]
    end
    @username = usrname
    @dkn_flag = flag
    @err = xerr
  end

  def dkn
    @agent.get("http://s11.sgame.vn")
    sleep 1
    password = re_password = "1"
    # username = [(print 'Username: '), gets.rstrip][1]
    url = 'http://s11.sgame.vn/ajax/dkn?txt_username=' + username + '&txt_password=' + password + '&re_txt_password=' + re_password + '&a=&c=&partner_id=&url=/'
    params = {
      txt_username: @username,
      txt_password: password,
      re_txt_password: re_password,
      a: nil,
      c: nil,
      partner_id: nil,
      url: "/"
    }
    request = @agent.post(url, params)#, {'Content-Type' => 'application/json'})
    dkn_body = JSON.parse request.body
    puts dkn_body["msg"]
    @username = username
    @dkn_flag = dkn_body["err"].zero?
  end

  def buy_player
    succ = []
    err = []
    Parallel.each((1..T_NO).to_a, in_threads: T_NO) do
      begin
        b = @agent.post("http://play.s11.sgame.vn/shop/buy", BUY, {"Referer" => "http://play.s11.sgame.vn/gmc/main"})
        b = JSON.parse(b.body)
        profile = b["result"]["openItemMap"]["appliedList"].first["playerInventory"]["playerProfile"]
        if profile["mteamNo"] == TARGET
          succ.push(profile["plrName"])
        end
      rescue => e
        err.push(e)
      end
    end
    puts "Wait #{SLEE1} seconds"
    sleep SLEE1
    puts "=================== #{err.count} ERROR / #{succ.count} Good"
    @memo.warn("#{@username} #{err.count} ERROR / #{succ.count} Good")
    parse_lineup()
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
    selected = leagued = []
    # selected = jdata["players"].select do |j|
    #   j["playerInventory"]["playerProfile"]["mteamNo"] == TARGET
    # end.map{ |s| s["playerInventory"]["playerProfile"]["plrName"] }
    # leagued = jdata["players"].select do |j|
    #   j["playerInventory"]["playerProfile"]["mleagNo"] == LEAGUE
    # end.map{ |s| s["playerInventory"]["playerProfile"]["plrName"] }
    ActiveRecord::Base.transaction do
      jdata["players"].each do |j|
        if j["playerInventory"]["playerProfile"]["mteamNo"] == TARGET
          selected.push(j["playerInventory"]["playerProfile"]["plrName"])
        end
        if j["playerInventory"]["playerProfile"]["mleagNo"] == LEAGUE
          leagued.push(j["playerInventory"]["playerProfile"]["plrName"])
        end
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
      league_uid: LEAGUE,
      member_count: @team.players.where(team_uid: TARGET).count,
      league_count: @team.players.where(league_uid: LEAGUE).count,
      team_uid: TARGET
    )
    puts "#{@username}: #{selected.size} / #{jdata["players"].size}"
    @memo.info("#{@username}: #{selected.size} / #{jdata["players"].size}")
    if (T_NO == 20 && selected.size >= 4) || (selected.size >= 9)
      @choose.info("#{@username}: #{selected.size} / #{jdata["players"].size} / #{leagued.size} ALL [#{selected.join(',')}]")
      File.open("choose.csv", "a+") do |f|
        f.write([@username, selected.size, leagued.size, selected.join("-"), leagued.join("-")].join(",") + "\n")
      end
    end
    selected.each { |s| puts s }
  rescue => e
    puts e
    return if @err
    @err = true
    @agent.cookie_jar.clear!
    puts "Wait #{SLEE1} seconds"
    x = S11.new(@username, @dkn_flag, @err)
    sleep SLEE1
    x.login()
    puts "Wait #{SLEE2} seconds"
    sleep SLEE2
    x.parse_lineup()
  end

  def tao_team
    @agent.get("http://play.s11.sgame.vn/foundation/create")
    sleep 1
    check = true
    teamname = @username.capitalize
    teamname[-1] = teamname[-1].upcase
    teamname[-2] = teamname[-2].upcase
    puts teamname
    while check
      teamname ||= [(print 'Ten doi: '), STDIN.gets.chomp][1]
      coachname = teamname
      check1 = @agent.post("http://play.s11.sgame.vn/foundation/team/duplicated", {name: teamname}).body
      check2 = @agent.post("http://play.s11.sgame.vn/foundation/coach/duplicated", {name: coachname}).body
      check = check1 == "true" && check2 == "true"
      if check
        teamname = nil
      end
    end
    teamint = "SRW"
    params = {
      json: '{"teamName":"%s","teamInitials":"%s","coachName":"%s","motherTeam":%s,"players":%s,"natNo":0,"squadName":"XXX"}' % [teamname, teamint, coachname, TARGET, MAIN.inspect],
      path: "PC"
    }
    z = @agent.post("http://play.s11.sgame.vn/foundation/create2", params)
    if @dkn_flag && !@err
      puts "Delay login. Wait #{SLEE1} seconds"
      sleep SLEE1
    end
    JSON.parse(z.body)
  end

  def login
    login = {
      username: @username,
      password: "valentin0",
      url: "http://s11.sgame.vn/play"
    }
    login_page = @agent.post("http://s11.sgame.vn/ajax/login", login)
    login_page = JSON.parse(login_page.body)
    return unless login_page["err"] == 0
    @team = Team.where(login_name: @username).first_or_create
    puts login_page["msg"]
  end

  def dang_ky_team
    # @dkn_flag = @username = "toitest01"
    if @dkn_flag || dkn()
      login()
      @agent.get("http://s11.sgame.vn/play")
      if @err
        parse_lineup()
      else
        z = tao_team()
        if z["code"] == "SUCCESS"
          puts z["message"]
          buy_player()
        else
          puts "Error"
          S11.new(@username, true).dang_ky_team()
        end
      end
    end
  end
end
# a, b, c = ARGV[0], ARGV[1], ARGV[2]
# puts [a, b, c].inspect
# ("aa".."zz").each do |char|
#   begin
#     x = a.dup.insert(-3, char)
#     S11.new(x, b, c).dang_ky_team()
#   rescue => e
#     next
#   end
# end
