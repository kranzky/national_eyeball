#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

polling = Hash.new { |h, k| h[k] = { "2008" => {}, "2013" => {} } }
CSV.foreach("../polling_places_2008.csv", headers: true) do |row|
  polling[row[1]][:location] ||= [row[5].to_f, row[6].to_f]
  next if row[2] == "Exhausted Votes"
  name = row[3]
  name = "(none)" if row[3].strip.length == 0
  polling[row[1]]["2008"][name] = row[4].to_i
end
CSV.foreach("../polling_places_2013.csv", headers: true) do |row|
  polling[row[1]][:location] ||= [row[5].to_f, row[6].to_f]
  next if row[2] == "Exhausted Votes"
  name = row[3]
  name = "(none)" if row[3].strip.length == 0
  polling[row[1]]["2013"][name] = row[4].to_i
end

File.open("polling_places.json", "w") { |f| f.write(JSON.pretty_generate(polling)) }
