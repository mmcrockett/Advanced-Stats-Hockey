class RemoveEloProcessedFromGames < ActiveRecord::Migration
  def change
    remove_column :games, :elo_processed
  end
end
