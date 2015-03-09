class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :login_name
      t.integer :uid
      t.integer :team_uid
      t.integer :league_uid
      t.integer :member_count
      t.integer :league_count

      t.timestamps null: false
    end
  end
end
