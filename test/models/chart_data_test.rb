require 'test_helper'

class ChartDataTest < ActiveSupport::TestCase
  test "add throws if date is earlier" do
    chart_data = ChartData.new

    err = assert_raises { chart_data.add(seasons(:complete_2)).add(seasons(:complete)) }
    assert_match(/Expectation is that seasons are loaded in order/, err.message)
  end
end
