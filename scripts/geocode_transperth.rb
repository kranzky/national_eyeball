#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

index = {}
CSV.foreach("../stops.txt", headers: true) do |row|
  index[row[2]] = {
    name: row[4],
    pos: [row[6].to_f, row[7].to_f]
  }
end

stops = JSON.parse(File.read("stops.json"))
stops.keys.each do |stop_id|
  next unless index[stop_id]
  stops[stop_id][:name] = index[stop_id][:name]
  stops[stop_id][:pos] = index[stop_id][:pos]
end
File.open("stops.json", "w") { |f| f.write(JSON.pretty_generate(stops)) }
