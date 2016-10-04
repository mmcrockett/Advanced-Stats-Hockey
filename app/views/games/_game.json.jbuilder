json.extract! game, :id, :home_team_id, :home_score, :away_team_id, :away_score, :overtime, :game_date, :created_at, :updated_at
json.url game_url(game, format: :json)