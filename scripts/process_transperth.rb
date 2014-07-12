#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

files = {
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_March1-15.rpt' => 4009146,
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_March16-31.rpt' => 4825079,
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_April1-15.rpt' => 4043147,
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_April15-30.rpt' => 3098661
}
bus_stops = Hash.new { |h, k| h[k] = { on: 0, off: 0 } }
files.each do |filename, length|
  bar = ProgressBar.new(filename, length)
  CSV.foreach(filename, headers: true) do |row|
    bar.inc
    next unless row[2] == '0'
    bus_stops[row[5].to_i][:on] += 1
    bus_stops[row[8].to_i][:off] += 1
  end
end

File.open("stops.json", "w") { |f| f.write(JSON.pretty_generate(bus_stops)) }
