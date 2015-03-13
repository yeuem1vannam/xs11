class XTeam < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["#{Rails.env}_sqlite"].present? ? "#{Rails.env}_sqlite".to_sym : "#{Rails.env}".to_sym
  self.table_name = "teams"
  has_many :players, dependent: :destroy, foreign_key: :team_id, class_name: XPlayer.name
  after_commit :sync_to_main

  def to_main_data
    return unless Team.configurations[Rails.env]["adapter"] == "mysql2"
    team = Team.where(login_name: login_name).first_or_create
    team.update(self.attributes.except("id"))
    self.players.find_in_batches do |group|
      xplayers = []
      group.each do |p|
        player = team.players.where(uid: p.uid).first_or_initialize
        xe = []
        if p.player_info_id
          xe = ["id", "info"]
        else
          xe = ["id"]
        end
        player.assign_attributes(p.attributes.except(*xe).merge("team_id" => team.id))
        xplayers.push(player)
      end
      Player.import(xplayers, on_duplicate_key_update: Player.column_names - ["id"])
    end
  end

  private
  def sync_to_main
    if Rails.configuration.database_configuration["#{Rails.env}"]["adapter"] == "mysql2"
      self.to_main_data
    end
  end
end
