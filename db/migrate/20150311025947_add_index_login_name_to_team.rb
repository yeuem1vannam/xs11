class AddIndexLoginNameToTeam < ActiveRecord::Migration
  def change
    add_index :teams, :login_name
  end
end
