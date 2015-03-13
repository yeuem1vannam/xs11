class RenamePwdColumnFromTeams < ActiveRecord::Migration
  def change
    rename_column :teams, :pwd, :login_pwd
  end
end
