module PlayersHelper
  def s11_image_73 player = nil
    if player.present?
      (image_tag(player.s11_image_url, width: 73, height: 57) + content_tag(:p, player.name_grade) + content_tag(:p, player.possible_position)).html_safe
    else
      (content_tag(:p, "Missing") + "OR" + content_tag(:p, "Not use")).html_safe
    end
  end
end
