class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :login
      t.integer :uid

      t.timestamps null: false
    end
  end
end
