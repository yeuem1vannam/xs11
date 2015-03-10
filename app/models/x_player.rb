class XPlayer < ActiveRecord::Base
  establish_connection :development_sqlite
  self.table_name = "players"
  belongs_to :team, class_name: XTeam.name
  serialize :info, Hash
end
