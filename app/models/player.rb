class Player < ActiveRecord::Base
  # RW    / ST    / LW  / CAM / RM  / CM / LM / CDM / RB  / CB  / LB / GK
  # 2048  / 1024  / 512 / 256 / 128 / 64 / 32 / 16  / 8   / 4   / 2  / 1
  BW = 111111111111
  POS = {
    "RW" => 2048,
    "ST" => 1024,
    "LW" => 512,
    "CAM" => 256,
    "RM" => 128,
    "CM" => 64,
    "LM" => 32,
    "CDM" => 16,
    "RB" => 8,
    "CB" => 4,
    "LB" => 2,
    "GK" => 1
  }
  belongs_to :team
  belongs_to :player_info, class_name: PlayerInfo.name, foreign_key: :player_info_id
  # Comment this when you do re_arange_position
  serialize :info, Hash
  before_save :calc_position
  scope :grade_ordered, ->{order("field(grade, 3,2,7,1)")}

  def s11_image_url
    "http://images.s11.sgame.vn/pc/img_g/data/player_global/#{uid}_73.png"
  end

  def name_grade
    x = case grade
    when 1 #normal
      :default
    when 2 # gold
      :warning
    when 3 # Live
      :danger
    when 7 # silver
      :primary
    end
    "<span class=\"label label-#{x}\">#{name}</span>".html_safe
  end

  def possible_position
    POS.select { |p| POS[p] & position != 0 }.keys.join("|")
  rescue
    self.calc_position
    self.save
    self.possible_position
  end

  def calc_position
    # Uncommend when do re_arange_position
    # xinfo = YAML.load(info)
    # self.position = POS.values_at(*xinfo["positionGrade"].keys).sum rescue nil
    self.position = POS.values_at(*player_info.info["positionGrade"].keys).sum rescue nil
  end

  class << self
    def re_arange_position
      Player.where(position: nil).where.not(info: nil).find_in_batches do |group|
        group.each do |p|
          p.calc_position
        end
        Player.import(group, on_duplicate_key_update: [:position])
      end
    end

    def migrate_info
      infos = []
      Player.where.not(info: nil).select(:uid, :info).uniq.each do |p|
        xinfo = PlayerInfo.where(info_no: p.uid).first_or_initialize
        xinfo.info = p.info
        infos.push(xinfo)
      end
      PlayerInfo.import(infos, on_duplicate_key_update: [:info])
    end

    def reference_to_player_info
      pinfos = PlayerInfo.all.inject({}) { |r , e| r[e.info_no] = e.id; r }
      # Player.find_in_batches do |group|
      #   xgroup = []
      #   group.each do |p|
      #     i = pinfos[p.uid]
      #     next unless i
      #     p = Player.new(p.attributes.slice("id").merge("player_info_id" => i))
      #     xgroup.push p
      #   end
      #   Player.import(xgroup, on_duplicate_key_update: [:player_info_id])
      # end
    end
  end
end
