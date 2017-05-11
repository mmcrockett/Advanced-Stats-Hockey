class CreateElos < ActiveRecord::Migration
  def change
    create_table :elos do |t|
      t.integer :value, :null => false
      t.date :sample_date, :null => false
      t.boolean :ignore, :null => false, :default => true
      t.references :team, index: true, foreign_key: true, :null => false
      t.references :game, index: true, foreign_key: true, :null => false

      t.timestamps null: false
    end
  end
end
