require 'set'
require 'colorize'

PATHS = [
  '/mnt/c/Users/Philip Ross/Downloads/v',
  # '/mnt/c/Users/Philip Ross/Downloads/from the new world',
  # '/mnt/c/Users/Philip Ross/Downloads/Big Windup!/Season 1',
  # '/mnt/c/Users/Philip Ross/Downloads/Big Windup!/Season 2',

# '/mnt/c/Users/Philip Ross/Downloads/Accel World',
]
PATHS.each {|p| p << '/' unless p.end_with? '/'}
OPTS = {encoding: 'UTF-8'}
RENAME = true
RESULTS = []
ANIME = false
IGNORE_PREFIX = '[bonkai77]'
# NUMBER_INCREMENT = -328

def expand_paths
  expanded = Set.new
  PATHS.each do |path|
    expanded << path and next unless path.end_with?('*') || path.end_with?('*/')
    dir_path = path.gsub('*/', '').gsub('*', '')
    entries = Dir.entries dir_path, OPTS
    entries.each do |entry|
      next if entry == '.' || entry == '..' || entry == 'desktop.ini'
      expanded << dir_path + entry + '/'
    end

  end

  puts expanded.inspect

  # exit
end

def main
  expand_paths

  PATHS.each do |path|
    puts ''
    rename_show path, false, true
    has_no_missing = analyze_missing
    first_number = has_no_missing
    if !has_no_missing
      puts 'first number has missing episode numbers'.light_yellow
      RESULTS.clear
      rename_show path, false, false
      has_no_missing = analyze_missing
      first_number = false
    end

    if RENAME && has_no_missing
      rename_show path, true, first_number
      puts 'Done renaming'.light_green
    else
      puts 'Renaming not enabled'.light_yellow
    end
    RESULTS.clear
    puts "\nanalyzing " + (first_number ? 'first number' : 'second number')
  end
end

def rename_show(path, rename, first_number)
  entries = Dir.entries path, OPTS
  count = 0
  entries.each do |entry|
    next if entry == '.' || entry == '..' || entry == 'desktop.ini'
    if File.directory?("#{path}/#{entry}")
      rename_season path + '/' + entry, rename, first_number
    else
      rename_episode path, entry, rename, first_number
    end
    count += 1
    # break if count > 2
  end
end

def rename_season(path, rename, first_number)
  episodes = Dir.entries path, OPTS
  count = 0
  episodes.each do |episode_name|
    next if episode_name == '.' || episode_name == '..' || episode_name == 'desktop.ini'
    rename_episode path, episode_name, rename, first_number
    count += 1
    # break if count > 2
  end
end

def rename_episode(folder_path, name, rename, first_number)
  return unless name.include? '.'
  episode_number = extract_number name, rename, first_number
  puts "Not renaming '#{name.light_yellow}'" or return unless episode_number
  if rename
    File.rename(folder_path + '/' + name, folder_path + '/' + episode_number.to_s + File.extname(name))
  else
    RESULTS << episode_number
  end
end

def extract_number(str, rename, first_number)
  str = str[IGNORE_PREFIX.length..-1] if str.start_with? IGNORE_PREFIX
  puts str if !rename && first_number
  numb = first_number ? str[/\d+/] : str.scan(/\d+/)[1]
  # numb = str[/E\d+/][/\d+/].to_i
  # numb = str[/E\d+-E\d+/]&.gsub('E', '') || numb
  return unless numb
  numb = numb.to_i
  numb += NUMBER_INCREMENT if defined? NUMBER_INCREMENT

  numb if numb < 1900 # probably a movie
  numb
end

def escape_glob(s)
  s.gsub(/[\\\{\}\[\]\?]/) {|x| "\\"+x}
end

def yesno(prompt = 'Continue?', default = true)
  a = ''
  s = default ? '[Y/n]' : '[y/N]'
  d = default ? 'y' : 'n'
  until %w[y n].include? a
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    a = ask("#{prompt} #{s} ") {|q| q.limit = 1; q.case = :downcase}
    $VERBOSE = original_verbosity
    a = d if a.length == 0
  end
  a == 'y'
end

def analyze_missing
  missing_episodes_numbers = []
  set = Set.new
  duplicates = RESULTS.select {|e| !set.add?(e)}

  puts "duplicate episode numbers: #{duplicates.map(&:to_s).map(&:light_red).join(', ')}" unless duplicates.empty?
  RESULTS.min.upto(RESULTS.max).each do |numb|
    missing_episodes_numbers << numb unless set.include? numb
  end
  if missing_episodes_numbers.empty?
    puts 'no missing episodes'.light_green
  else
    puts "missing episodes: #{missing_episodes_numbers.map(&:to_s).map(&:light_red).join(', ')}"
  end
  return missing_episodes_numbers.empty? && duplicates.empty?
end

main
