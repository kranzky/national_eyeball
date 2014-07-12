#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

centres = []
bar = ProgressBar.new("thinking", 1027)
CSV.foreach("../Childcare-by-location.csv", headers: true) do |row|
  bar.inc
  address = "#{row[4]}, #{row[5]}, #{row[6]}, #{row[7]}"
  centres << {
    name: row[2],
    location: Geocoder::coordinates(address),
    places: row[12].to_i
  }
end

File.open("childcare_centres.json", "w") { |f| f.write(JSON.pretty_generate(centres)) }
