class PointhogParser
  attr_reader :games
  attr_reader :teams

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
    game   = {}
    cells  = row.css('th,td')
    status = cells[-1].text().strip().downcase()

    if (true == status.include?(POINTHOG_FINISHED_GAME_IDENTIFIER.downcase()))
      POINTHOG_COLUMNS.each do |column_name|
        game[column_name] = cells[columns[column_name]].text().strip().downcase().titleize()
      end

      game[HOME_SCORE_KEY] = PointhogParser.parse_score(cells, columns[POINTHOG_HOME_COLUMN])
      game[AWAY_SCORE_KEY] = PointhogParser.parse_score(cells, columns[POINTHOG_AWAY_COLUMN])
      game[POINTHOG_DATE_COLUMN] = PointhogParser.parse_datetime(game[POINTHOG_DATE_COLUMN])

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
  def parse_schedule(page)
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

        if (false == game.empty?)
          @teams << game[POINTHOG_HOME_COLUMN]
          @teams << game[POINTHOG_AWAY_COLUMN]
          @games << game
        else
          @season_complete = false
          break
        end
      end
    end

    return self
  end
end
