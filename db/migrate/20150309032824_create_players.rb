class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.references :team, index: true
      t.string :name
      t.integer :uid
      t.integer :team_uid
      t.integer :league_uid
      t.integer :grade
      t.text :info

      t.timestamps null: false
    end
    add_foreign_key :players, :teams
  end
end
