require 'fileutils'
require 'colorize'
require 'active_support'
require 'active_support/number_helper'

PATH = 'F:\anime'
OPTS = {encoding: 'UTF-8'}
SHOWS = {}
RESULTS = []

class Anime
  attr_accessor :name, :bytes
  def initialize(name, bytes)
    @name = name
    @bytes = bytes
  end

  def size
    ActiveSupport::NumberHelper.number_to_human_size(@bytes, {precision: 5, strip_insignificant_zeros: false})
  end

  def to_s
    "#{@name.cyan}: #{size}"
  end
end

def main
  shows = Dir.entries PATH, OPTS
  shows.each do |show|
    next if show == '.' || show == '..' || show == 'zWatched' || show == 'desktop.ini'
    calculate_size show
  end
  PATH << '/zWatched'
  watched_shows = Dir.entries PATH, OPTS
  watched_shows.each do |show|
    next if show == '.' || show == '..' || show == 'desktop.ini'
    calculate_size show
  end

end

def directory_size(path)
  # path << '/' unless path.end_with?('/')

  raise RuntimeError, "#{path} is not a directory" unless File.directory?(path)

  total_size = 0
  entries = Dir.entries path, OPTS
  entries.each do |f|
    next if f == '.' || f == '..' || f == 'zWatched' || f == 'desktop.ini'
    f = "#{path}\\#{f}"
    total_size += File.size(f) if File.file?(f) && File.size?(f)
    total_size += directory_size f if File.directory? f
  end
  total_size
end

def calculate_size(show)
  puts "calculating size for #{show}"
  size = directory_size "#{PATH}/#{show}"
  if SHOWS.include? show
    anime = SHOWS[show]
    anime.bytes += size
  else
    anime = Anime.new(show, size)
    RESULTS << anime
    SHOWS[anime.name] = anime
  end
end

main
RESULTS.sort_by(&:name)
File.open('./anime.txt', 'w') do |file|
  RESULTS.each do |anime|
    file.puts(anime.name)
  end
end
RESULTS.sort_by!(&:bytes).reverse!
puts RESULTS
