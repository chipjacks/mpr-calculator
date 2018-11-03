require "minitest/autorun"

class TestReadTimes < Minitest::Test

  RUNNER_TYPES = %w(neutral aerobic speed)

  def test_race_times
    RUNNER_TYPES.each do |rt|
      expected = File.read(File.join("fixtures", "#{rt}Race.json"))
      actual = %x(ruby readTimes.rb -f race -t #{rt} | jq '.')
      assert_equal expected, actual
    end
  end

  def test_training_paces
    RUNNER_TYPES.each do |rt|
      expected = File.read(File.join("fixtures", "#{rt}Training.json"))
      actual = %x(ruby readTimes.rb -f training -t #{rt} | jq '.')
      assert_equal expected, actual
    end
  end

end