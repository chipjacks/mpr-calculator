require "minitest/autorun"

class TestReadTimes < Minitest::Test

  def test_race_times
    expected = File.read("neutralRunnerRaceTimes.json")
    actual = %x(ruby readTimes.rb -t race | jq '.')
    assert_equal expected, actual
  end

  def test_training_paces
    expected = File.read("neutralRunnerTrainingPaces.json")
    actual = %x(ruby readTimes.rb -t training | jq '.')
    assert_equal expected, actual
  end

end