#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

filename = "../pc_full_lat_long.csv"

codes = Hash.new { |h, k| h[k] = {} }
CSV.foreach(filename, headers: true) do |row|
  codes[row[2]][row[1]] = row[0].to_i
end

File.open("codes.json", "w") { |f| f.write(JSON.pretty_generate(codes)) }
