class Team < ActiveRecord::Base
  default_scope {where("member_count >= 4")}
  has_many :players, dependent: :destroy
  class << self
    def regist_new(prefix = nil)
      ("aa".."zz").each do |char|
        begin
          x = prefix.dup.insert(-3, char)
          S11.new(x).dang_ky_team()
        rescue => e
          Rails.logger.error(e)
          next
        end
      end
    end
  end
end
