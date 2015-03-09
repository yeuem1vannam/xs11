class RescanJob < ActiveJob::Base
  queue_as :default

  def perform(team_id, kookie)
    team = Team.find(team_id)
    # Do something later
    X11.new(kookie).get_lineup()
    binding.pry
  end
end
