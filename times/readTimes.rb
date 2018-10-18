require 'json'
require 'nokogiri'
require 'pry'

def timeToSeconds(timeStr)
  hrs, mins, secs = timeStr.split(':').map(&:to_i)
  (hrs * 60 * 60) + (mins * 60) + secs
end

 
raceTimesHTML = File.open("MPRRaceTimes.html") { |f| Nokogiri::HTML(f) }
raceTimesList = raceTimesHTML.xpath("//*[text()[contains(.,'Neutral Runners Charts')]]/following::table[1]//td/div/text()")
raceTimesList = raceTimesList.to_a.select { |t| !t.to_s.sub(/\S/, '').empty? }

distances = %w(5k 8k 5mi 10k 15k 10mi 20k HalfMarathon 25k 30k Marathon)
dict = {}

distances.each_with_index do |dist, idx|
  row = []
  a = 0
  b = 0

  c = idx * 10
  12.times do |j|
    a = j * 190
    5.times do |i|
      b = i * 2 + 1
      row << raceTimesList[a + b + c]
    end
  end
  row << raceTimesList[a + b + c - 1] # grab lower limit for level 60
  dict[dist] = row
end

puts JSON.generate(dict)