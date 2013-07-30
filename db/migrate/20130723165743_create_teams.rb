class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name, :null => false
      t.integer :games
      t.integer :points
      t.integer :goals_scored
      t.integer :goals_allowed
      t.references :season, :null => false

      t.timestamps
    end
    add_index :teams, :season_id
  end
end
