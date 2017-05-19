class DropElosTable < ActiveRecord::Migration
  def change
    drop_table :elos
  end
end
