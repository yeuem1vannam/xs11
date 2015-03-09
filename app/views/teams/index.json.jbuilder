json.array!(@teams) do |team|
  json.extract! team, :id, :login_name, :uid, :team_uid, :league_uid, :member_count, :league_count
  json.url team_url(team, format: :json)
end
