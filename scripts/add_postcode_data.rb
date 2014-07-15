#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'open-uri'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

CODES = JSON.parse(File.read('../codes.json'))
def add_postcode(filename)
  data = JSON.parse(File.read(filename))
  return unless data['state']
  return unless data['suburb']
  return if data['postcode']
  return unless CODES[data['state']]
  data['postcode'] = CODES[data['state']][data['suburb'].upcase].to_i
  File.open(filename, "w") { |f| f.write(JSON.pretty_generate(data)) }
end

bar = ProgressBar.new("doing", 8511)
Dir.glob("./api/australua/states/*/suburbs/*.json").each do |filename|
  next if filename =~ /(index|error)/
  bar.inc
  add_postcode(filename)
end
