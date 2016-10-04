class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :home_team_id, :null => false
      t.integer :home_score, :null => false
      t.integer :away_team_id, :null => false
      t.integer :away_score, :null => false
      t.boolean :overtime, :null => false
      t.boolean :playoff, :null => false, :default => false
      t.boolean :elo_processed, :null => false, :default => false
      t.date :game_date, :null => false

      t.timestamps null: false
    end
  end
end
