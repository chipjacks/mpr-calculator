require "minitest/autorun"

class TestReadTimes < Minitest::Test

  def test_race_times
    expected = File.read("neutralRunnerRaceTimes.json")
    actual = %x(ruby readTimes.rb -f race -t neutral | jq '.')
    assert_equal expected, actual
  end

  def test_training_paces
    expected = File.read("neutralRunnerTrainingPaces.json")
    actual = %x(ruby readTimes.rb -f training -t neutral | jq '.')
    assert_equal expected, actual
  end

end