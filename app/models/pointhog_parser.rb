class PointhogParser
  HOME_SCORE_KEY = :hscore.to_s
  AWAY_SCORE_KEY = :ascore.to_s
  SHOOTOUT_KEY   = :shootout.to_s

  POINTHOG_DATE_FORMAT = "%m/%d/%y %l:%M %p"

  POINTHOG_FINISHED_GAME_IDENTIFIER = 'Final'
  POINTHOG_SHOOTOUT_GAME_IDENTIFIER = 'SO'

  POINTHOG_DATE_COLUMN = 'date'
  POINTHOG_HOME_COLUMN = 'home'
  POINTHOG_AWAY_COLUMN = 'away'
  POINTHOG_COLUMNS = [POINTHOG_DATE_COLUMN, POINTHOG_HOME_COLUMN, POINTHOG_AWAY_COLUMN]

  def self.parse_schedule(page)
    games   = []
    columns = {}
    schedule_table   = page.css('table[id*=Schedule]')

    schedule_table.css('tr').each do |row|
      if (true == row[:class].include?("Header"))
        columns = PointhogParser.parse_header_row(row)
      elsif (true == columns.empty?)
        raise "!ERROR: Header row not found."
      else
        game = PointhogParser.parse_row(columns, row)

        if (false == game.empty?)
          games << game
        end
      end
    end

    return games
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
        game[column_name] = cells[columns[column_name]].text().strip().downcase()
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
    if (true == date_str.is_a?(String))
      return DateTime.strptime("#{date_str} Central Time (US & Canada)", "#{POINTHOG_DATE_FORMAT} %Z")
    else
      return date_str
    end
  end

  def self.parse_score(cells, column_index)
    v_str = cells[column_index + 1].text().strip()
    v     = v_str.to_i

    if ("#{v}" != v_str)
      raise "!ERROR: Couldn't parse '#{column_index}' score correctly '#{v}' != '#{v_str}'."
    end

    return v
  end
end
