class AddPwdToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :pwd, :string
  end
end
