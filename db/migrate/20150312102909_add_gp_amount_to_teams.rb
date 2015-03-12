class AddGpAmountToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :teamname, :string
    add_column :teams, :team_sign, :string
    add_column :teams, :gp_amount, :integer
    add_column :teams, :registered, :boolean, default: false
  end
end
