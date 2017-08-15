namespace :elo do
  desc "Check for new articles."
  task(:update => :environment) do
    games = 0

    Season.where(:complete => false).each do |season|
      games -= season.games.size
      season.load_data
      games += season.games.size
    end

    puts "'#{games.size}' new games loaded."
  end
end
