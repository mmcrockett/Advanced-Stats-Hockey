class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name, :null => false
      t.string :franchise, :null => false
      t.references :season, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
