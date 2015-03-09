json.array!(@players) do |player|
  json.extract! player, :id, :team_id, :name, :uid, :team_uid, :league_uid, :grade
  json.url player_url(player, format: :json)
end
