class PointhogParser
  attr_reader :games
  attr_reader :teams
  attr_reader :pending_games

  HOME_SCORE_KEY = :home_score.to_s
  AWAY_SCORE_KEY = :away_score.to_s
  SHOOTOUT_KEY   = :shootout.to_s

  POINTHOG_DATE_FORMAT = "%m/%d/%y %l:%M %p"

  POINTHOG_FINISHED_GAME_IDENTIFIER = 'Final'
  POINTHOG_SHOOTOUT_GAME_IDENTIFIER = 'SO'

  POINTHOG_DATE_COLUMN = 'date'
  POINTHOG_HOME_COLUMN = 'home'
  POINTHOG_AWAY_COLUMN = 'away'
  POINTHOG_COLUMNS = [POINTHOG_DATE_COLUMN, POINTHOG_HOME_COLUMN, POINTHOG_AWAY_COLUMN]

  POINTHOG_IGNORE_TEAMS = ["All Star Game"]

  DIVISION_SCHEDULE_URL_IDENTIFIER = "DivisionSchedule"

  def self.load_html(pointhog_url)
    if (false == pointhog_url.include?(DIVISION_SCHEDULE_URL_IDENTIFIER))
      raise "!ERROR: Expect a url containing '#{DIVISION_SCHEDULE_URL_IDENTIFIER}' got '#{pointhog_url}'."
    end

    return Nokogiri::HTML(open(pointhog_url))
  end

  def initialize(page)
    @season_complete = true
    @games = []
    @pending_games = []
    @teams = Set.new

    parse_schedule(page)
  end

  def season_complete?
    return @season_complete
  end

  def self.parse_header_row(row)
    columns = {}

    row.css('th,td').each_with_index do |cell,i|
      column_name = cell.text().strip().downcase()
      if (true == POINTHOG_COLUMNS.include?(column_name))
        columns[column_name] = i
      end
    end

    if ((columns.keys.size != POINTHOG_COLUMNS.size) || (POINTHOG_COLUMNS & columns.keys != POINTHOG_COLUMNS))
      raise "!ERROR: Couldn't find all columns '#{row}' '#{columns.keys}' '#{POINTHOG_COLUMNS}'."
    end

    return columns
  end

  def self.parse_row(columns, row)
    game   = {}.with_indifferent_access
    cells  = row.css('th,td')
    status = cells[-1].text().strip().downcase()

    POINTHOG_COLUMNS.each do |column_name|
      game[column_name] = cells[columns[column_name]].text().strip().downcase().titleize()
    end
    game[POINTHOG_DATE_COLUMN] = PointhogParser.parse_datetime(game[POINTHOG_DATE_COLUMN])

    if (true == status.include?(POINTHOG_FINISHED_GAME_IDENTIFIER.downcase()))
      game[HOME_SCORE_KEY] = PointhogParser.parse_score(cells, columns[POINTHOG_HOME_COLUMN])
      game[AWAY_SCORE_KEY] = PointhogParser.parse_score(cells, columns[POINTHOG_AWAY_COLUMN])

      if (true == status.include?(POINTHOG_SHOOTOUT_GAME_IDENTIFIER.downcase))
        game[SHOOTOUT_KEY] = true
      else
        game[SHOOTOUT_KEY] = false
      end
    end

    return game
  end

  def self.parse_datetime(date_str)
    value = nil

    if (true == date_str.is_a?(String))
      value = DateTime.strptime("#{date_str} Central Time (US & Canada)", "#{POINTHOG_DATE_FORMAT} %Z")
    else
      value = date_str
    end

    return Game.new({:game_date => value}).game_date
  end

  def self.parse_score(cells, column_index)
    v_str = cells[column_index + 1].text().strip()
    v     = v_str.to_i

    if ("#{v}" != v_str)
      raise "!ERROR: Couldn't parse '#{column_index}' score correctly '#{v}' != '#{v_str}'."
    end

    return v
  end

  private
  def parse_schedule(page, options = {:unfinished_games => false})
    columns = {}
    schedule_table   = page.css('table[id*=Schedule]')

    if (nil == schedule_table)
      raise "!ERROR: Couldn't find 'Schedule' in html."
    end

    schedule_table.css('tr').each do |row|
      if (true == row[:class].include?("Header"))
        columns = PointhogParser.parse_header_row(row)
      elsif (true == columns.empty?)
        raise "!ERROR: Header row not found."
      else
        game = PointhogParser.parse_row(columns, row)

        if (false == PointhogParser.ignore?(game))
          if (true == game.include?(SHOOTOUT_KEY))
            @teams << game[POINTHOG_HOME_COLUMN]
            @teams << game[POINTHOG_AWAY_COLUMN]
            @games << game
          else
            @pending_games << game
            @season_complete = false
          end
        else
          @season_complete = false
          break
        end
      end
    end

    return self
  end

  def self.ignore?(pointhog_game)
    home_team = pointhog_game[POINTHOG_HOME_COLUMN]
    away_team = pointhog_game[POINTHOG_AWAY_COLUMN]

    if (true == pointhog_game.empty?)
      return true
    elsif ((true == POINTHOG_IGNORE_TEAMS.include?(home_team)) || (true == POINTHOG_IGNORE_TEAMS.include?(away_team)))
      Rails.logger.warn("Ignoring game '#{pointhog_game}' because a team matches '#{POINTHOG_IGNORE_TEAMS}'.")
      return true
    else
      return false
    end
  end
end
