#!/usr/local/bin/ruby

require 'net/http'
require 'json'
require 'time'

class Track
  def initialize(name:, artist:, album:, time_played:)
    @name = name
    @artist = artist
    @album = album
    @time_played = time_played
  end

  def to_s
    local_timezone_offset = Time.now.strftime("%:z")
    local_time_played = @time_played.localtime(local_timezone_offset)
    pretty_time = local_time_played.strftime('%l:%M:%S%P')
    "#{pretty_time}  '#{@name}' - #{@album} - #{@artist}"
  end
end

ABC_RADIO_DOMAIN = 'music.abcradio.net.au'.freeze
ABC_JAZZ = 'jazz'.freeze
TRIPLEJ = 'triplej'.freeze
AVAILABLE_STATIONS = [ABC_JAZZ, TRIPLEJ].freeze

def main(radio_station)
  number_of_tracks_to_fetch = 5
  uri = URI("https://#{ABC_RADIO_DOMAIN}/api/v1/plays/search.json")
  uri.query = URI.encode_www_form(station: radio_station,
                                  limit: number_of_tracks_to_fetch,
                                  order: 'desc')
  response = Net::HTTP.get_response(uri)

  response_data = JSON.parse(response.body)

  track_data = response_data['items']
  tracks = track_data.map do |track|
    time_played_raw = track['played_time']
    time_played = Time.parse(time_played_raw)
    name = track['recording']['title']
    artist = track['recording']['artists'].first()['name']
    release_data = track['recording']['releases']
    album = release_data.map { |release| release['title'] }.join(', ')
    Track.new(name: name, artist: artist, album: album, time_played: time_played)
  end

  tracks.each do |track|
    puts track.to_s
  end
end

if ARGV.length != 1 || !AVAILABLE_STATIONS.include?(ARGV[0])
  puts "usage: abc_recently_played #{AVAILABLE_STATIONS.join('|')}"
else
  radio_station = ARGV[0]
  main(radio_station)
end
