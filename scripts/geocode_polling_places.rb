#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

data = JSON.parse(File.read("api/australia/states/WA/amenities/polling_places.json"))
bar = ProgressBar.new("thinking", 103)
data.each do |name, poll|
  next unless poll['location'].any? { |v| v == 0 }
  poll['location'] = Geocoder::coordinates(name)
end

File.open("api/australia/states/WA/amenities/polling_places.json", "w") { |file| file.write(JSON.pretty_generate(data)) }
