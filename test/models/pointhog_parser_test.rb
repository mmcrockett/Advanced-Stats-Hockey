require 'test_helper'

class PointhogParserTest < ActiveSupport::TestCase
  def setup
    @sample_html = {}

    @sample_html[:header] = <<-EOS
      <tr class="gridRowHeaderDefault hello">
			  <th scope="col">&nbsp;</th>
        <th align="left" scope="col">Date</th>
        <th align="left" scope="col">Facility</th>
        <th align="left" scope="col">Res.</th>
        <td align="left" style="font-weight:bold;">Div</td>
        <th align="left" scope="col" style="border-style:None;">Away</th>
        <th scope="col">&nbsp;</th>
        <th align="left" scope="col" style="border-style:None;">Home</th>
        <th scope="col">&nbsp;</th>
        <th scope="col" style="border-style:None;">&nbsp;</th>
      </tr>
    EOS

    @sample_html[:shootout] = <<-EOS
      <tr class="gridAltRowDefault" style="white-space:nowrap;">
        <td style="width:20px;"><b>4</b></td>
        <td align="left">09/12/16 8:45 PM</td>
        <td align="left">Northcross</td>
        <td align="left">Rink</td>
        <td align="left" style="white-space:nowrap;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Division.aspx?YMcmS6Ms5aaQa2'>B1 </a>
        </td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Team.aspx?XW2QTGMU5aaUaY'>SIMPLE JACKS </a>
        </td>
        <td>2</td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Team.aspx?PG2ATGME5aa8a4'><b>BLACK JACK</b> </a>
        </td>
        <td><b>3</b></td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Game.aspx?uUxFPGMA5aaIaK'>Final (SO) </a>
        </td>
      </tr>
    EOS

    @sample_html[:game] = <<-EOS
      <tr class="gridRowDefault" style="white-space:nowrap;">
        <td style="width:20px;"><b>5</b></td>
        <td align="left">09/12/16 10:00 PM</td>
        <td align="left">Northcross</td>
        <td align="left">Rink</td>
        <td align="left" style="white-space:nowrap;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Division.aspx?YMcmS6Ms5aaQa2'>B1 </a>
        </td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Team.aspx?Wh2WTWMe5aaOaR'>HIGHLANDERS </a>
        </td>
        <td>0</td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Team.aspx?NW2MTaMk5aaYaS'><b>CROWN KINGS</b> </a>
        </td>
        <td><b>6</b></td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Game.aspx?sCxTPiMg5aawaw'>Final </a>
        </td>
     </tr>
    EOS

    @sample_html[:not_played_game] = <<-EOS
      <tr class="gridRowDefault" style="white-space:nowrap;">
        <td style="width:20px;"><b>13</b></td>
        <td align="left">09/27/16 7:00 PM</td>
        <td align="left">HEB</td>
        <td align="left">Rink</td>
        <td align="left" style="white-space:nowrap;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Division.aspx?YMcmS6Ms5aaQa2'>B1 </a>
        </td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Team.aspx?Wh2WTWMe5aaOaR'>HIGHLANDERS </a>
        </td>
        <td></td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/Team.aspx?IB2eTqM25aauaj'>JUNIOR EH'S </a>
        </td>
        <td></td>
        <td style="border-style:None;">
          <a class='' href='http://www.PointHogSports.com/IceHockey/League/ScoreSheet.aspx?Jqw2PiMM5aa0ag' target='_blank''>SS </a>
        </td>
     </tr>
    EOS

    @sample_html[:table] = <<-EOS
      <table class="gridDefault" cellspacing="0" rules="all" border="1" id="ContentMain_GameScheduleGrid1_Grid1" style="border-collapse:collapse;">
      #{@sample_html[:header]}
      #{@sample_html[:shootout]}
      #{@sample_html[:game]}
      #{@sample_html[:not_played_game]}
      </table>
    EOS

    page = Nokogiri::HTML(@sample_html[:header])
    @columns = PointhogParser.parse_header_row(page)
  end

  test "can parse schedule" do
    page = Nokogiri::HTML(@sample_html[:table])
    games = PointhogParser.parse_schedule(page)

    assert_equal(2, games.size)

    games.each do |g|
      assert_equal(6, g.keys.size)

      g.each do |k,v|
        assert_not_nil(v)
      end
    end
  end

  test "raises error if header row not found" do
    bad_table = "#{@sample_html[:table]}".gsub("Header", "blah")
    page = Nokogiri::HTML(bad_table)

    assert_raises do |r|
      PointhogParser.parse_schedule(page)
    end
  end

  test "if header not found fail." do
    sample_header = "#{@sample_html[:header]}".gsub("Date", "blah")
    page = Nokogiri::HTML(sample_header)

    assert_raises do |r|
      PointhogParser.parse_header_row(page)
    end
  end

  test "can get headers" do
    assert_equal(1, @columns[PointhogParser::POINTHOG_DATE_COLUMN])
    assert_equal(5, @columns[PointhogParser::POINTHOG_AWAY_COLUMN])
    assert_equal(7, @columns[PointhogParser::POINTHOG_HOME_COLUMN])
  end

  test "empty for game that has not been played" do
    page = Nokogiri::HTML(@sample_html[:not_played_game])
    game = PointhogParser.parse_row(@columns, page.css('tr').first)

    assert(game.empty?)
  end

  test "can parse shootout row" do
    page = Nokogiri::HTML(@sample_html[:shootout])
    game = PointhogParser.parse_row(@columns, page.css('tr').first)

    assert_equal(DateTime.new(2016, 9, 12, 8+12, 45, 0, '-06:00'), game[PointhogParser::POINTHOG_DATE_COLUMN])
    assert_equal("SIMPLE JACKS".downcase(), game[PointhogParser::POINTHOG_AWAY_COLUMN])
    assert_equal(2, game[PointhogParser::AWAY_SCORE_KEY])
    assert_equal("BLACK JACK".downcase(), game[PointhogParser::POINTHOG_HOME_COLUMN])
    assert_equal(3, game[PointhogParser::HOME_SCORE_KEY])
    assert_equal(true, game[PointhogParser::SHOOTOUT_KEY])
  end

  test "can parse non shootout row" do
    page = Nokogiri::HTML(@sample_html[:game])

    game = PointhogParser.parse_row(@columns, page.css('tr').first)

    assert_equal(DateTime.new(2016, 9, 12, 10+12, 0, 0, '-06:00'), game[PointhogParser::POINTHOG_DATE_COLUMN])
    assert_equal("HIGHLANDERS".downcase(), game[PointhogParser::POINTHOG_AWAY_COLUMN])
    assert_equal(0, game[PointhogParser::AWAY_SCORE_KEY])
    assert_equal("CROWN KINGS".downcase(), game[PointhogParser::POINTHOG_HOME_COLUMN])
    assert_equal(6, game[PointhogParser::HOME_SCORE_KEY])
    assert_equal(false, game[PointhogParser::SHOOTOUT_KEY])
  end

  test "fails if score not an integer" do
    bad_hscore_html = "#{@sample_html[:game]}".gsub(">6<", ">0a<")
    bad_ascore_html = "#{@sample_html[:game]}".gsub(">0<", "><")

    bad_hscore_tr = Nokogiri::HTML(bad_hscore_html).css('tr').first
    bad_ascore_tr = Nokogiri::HTML(bad_ascore_html).css('tr').first

    assert_raises do |r|
      PointhogParser.parse_row(@columns, bad_hscore_tr)
    end

    assert_raises do |r|
      PointhogParser.parse_row(@columns, bad_ascore_tr)
    end

    begin
      PointhogParser.parse_row(@columns, bad_hscore_tr)
    rescue Exception => e
      assert("#{e}".include?("parse"))
      assert("#{e}".include?("#{@columns[PointhogParser::POINTHOG_HOME_COLUMN]}"))
    end

    begin
      PointhogParser.parse_row(@columns, bad_ascore_tr)
    rescue Exception => e
      assert("#{e}".include?("parse"))
      assert("#{e}".include?("#{@columns[PointhogParser::POINTHOG_AWAY_COLUMN]}"))
    end
  end
end
