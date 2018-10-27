require 'json'
require 'nokogiri'
require 'pry'
require 'optparse'
require 'optparse/time'

OptionParser.new do |parser|
  parser.on("-t", "--table TABLE", %w(race training), "Choose which table to parse") do |table|
    @table = table
  end
end.parse!

def timeToSeconds(timeStr)
  hrs, mins, secs = timeStr.split(':').map(&:to_i)
  (hrs * 60 * 60) + (mins * 60) + secs
end

def extractTableCells(htmlFile, tableTitle)
  file = File.open(htmlFile) { |f| Nokogiri::HTML(f) }
  cells = file.xpath("//*[text()[contains(.,'#{tableTitle}')]]/following::table[1]//td/div/text()")
  cells = cells.to_a.select { |t| !t.to_s.sub(/\S/, '').empty? }
end

def compileRaceTimes(cells)
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
        row << cells[a + b + c]
      end
    end
    row << cells[a + b + c - 1] # grab lower limit for level 60
    dict[dist] = row
  end
  dict
end

def compileTrainingPaces(cells)
  paces = %w(Easy Moderate SteadyState Brisk AerobicThreshold LactateThreshold Groove VO2Max Fast)
  res = []

  12.times do |row|
    5.times do |col|
      level = row * 5 + col
      res[level] = []
      cell_x = row * 99 + col * 2 + 1
      paces.each_with_index do |pace, idx|
        cell = cell_x + idx * 11
        res[level] << [cells[cell], cells[cell + 1]]
      end
    end
  end

  res
end
 
if @table == 'race' then
  raceTimesList = extractTableCells('MPRRaceTimes.html', 'Neutral Runners')
  puts JSON.generate(compileRaceTimes(raceTimesList))
elsif @table == 'training'
  trainingPacesList = extractTableCells('MPRTrainingPaces.html', 'Neutral Runners')
  puts JSON.generate(compileTrainingPaces(trainingPacesList))
end