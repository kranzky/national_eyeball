#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

hospitals = []
bar = ProgressBar.new("thinking", 779)
CSV.foreach("../publichospitalsinaihwhospitalsdatabase1213.csv", headers: true) do |row|
  bar.inc
  hospitals << {
    name: row[1],
    location: Geocoder::coordinates("#{row[6]}, #{row[7]} #{row[0]}"),
    beds: row[10].to_i,
    emergency: row[14] == 'Yes'
  }
end

File.open("api/australia/amenities/public_hospitals.json", "w") { |f| f.write(JSON.pretty_generate(hospitals)) }
