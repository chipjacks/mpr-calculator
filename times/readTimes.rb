require 'json'

def timeToSeconds(timeStr)
  hrs, mins, secs = timeStr.split(':').map(&:to_i)
  (hrs * 60 * 60) + (mins * 60) + secs
end

 
distances = %w(5k 8k 5mi 10k 15k 10mi 20k HalfMarathon 25k 30k Marathon)
times = File.readlines('neutralRunnerTimes.list').map(&:chomp)
dict = {}
distances.each_with_index do |dist, idx|
  row = []
  c = idx * 10
  12.times do |j|
    a = j * 190
    5.times do |i|
      b = i * 2 + 1
      # row << timeToSeconds(times[a + b + c])
      row << times[a + b + c]
    end
  end
  dict[dist] = row
end
puts JSON.generate(dict)