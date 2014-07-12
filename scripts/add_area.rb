#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'open-uri'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

AREAS = JSON.parse(File.read('areas.json'))
def add_area(filename)
  return unless AREAS[filename]
  data = JSON.parse(File.read(filename))
  data['spatial']['area'] = AREAS[filename]/10000
  File.open(filename, "w") { |f| f.write(JSON.pretty_generate(data)) }
end

bar = ProgressBar.new("doing", 8511)
Dir.glob("./api/**/statistics.json").each do |filename|
  bar.inc
  add_area(filename)
end
