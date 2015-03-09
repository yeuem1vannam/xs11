class Player < ActiveRecord::Base
  default_scope {order("field(grade, 3,2,7,1)")}
  belongs_to :team
  serialize :info, Hash

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
end
