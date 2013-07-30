class CreateSeasons < ActiveRecord::Migration
  def change
    create_table :seasons do |t|
      t.string :name, :null => false
      t.string :pointhog
      t.boolean :loaded, :default => false

      t.timestamps
    end
  end
end
