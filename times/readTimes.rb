require 'json'
require 'nokogiri'
require 'pry'
require 'optparse'
require 'optparse/time'

TABLES =
  { race:
    { neutral: 'Neutral_Runners',
      aerobic: 'Aerobic_Monsters',
      speed: 'Speed_Demons'
    },
    training:
    { neutral: 'NR',
      aerobic: 'AM',
      speed: 'SD'
    }
  }

FILES =
  { race: 'MPRRaceTimes.html',
    training: 'MPRTrainingPaces.html'
  }

OptionParser.new do |parser|
  parser.on("-f", "--file FILE", FILES.keys, "Choose which file to parse") do |file|
    @file = file.to_sym
  end

  parser.on("-t", "--table TABLE", TABLES[:race].keys, "Choose which runner type table to parse") do |table|
    @table = table.to_sym
  end

  parser.on("-h", "--help", "Prints this help") do
    puts parser
    exit
  end
end.parse!

def timeToSeconds(timeStr)
  hrs, mins, secs = timeStr.split(':').map(&:to_i)
  (hrs * 60 * 60) + (mins * 60) + secs
end

def extractTableCells(htmlFile, tableTitle)
  file = File.open(htmlFile) { |f| Nokogiri::HTML(f) }
  cells = file.xpath("//a[contains(@name,'#{tableTitle}')]/following::table[1]//td/div/text()")
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

def parseTable(table, runner_type)
  file_name = FILES[table]
  table_title = TABLES[table][runner_type]
  cells = extractTableCells(file_name, table_title)
  results =
    if table == :race
      compileRaceTimes(cells)
    else
      compileTrainingPaces(cells)
    end
end

if __FILE__ == $PROGRAM_NAME
  if @file && @table
    puts JSON.generate(parseTable(@file, @table))
  else
    TABLES.each do |table, runner_types|
      runner_types.each do |runner_type, table_title|
        results = parseTable(table, runner_type)
        puts runner_type.to_s + table.to_s.capitalize + ' = """'
        puts JSON.generate(results)
        puts '"""'
        puts
      end
    end
  end
end