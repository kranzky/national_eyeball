#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'date'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

def get_day(date)
  parsed = DateTime.parse(date)
  case parsed.strftime("%F")
  when '2014-03-03'
    :holiday
  when '2014-04-18'
    :holiday
  when '2014-04-21'
    :holiday
  when '2014-04-25'
    :holiday
  else
    parsed.strftime("%A").downcase.to_sym
  end
end

days = Hash.new { |h, k| h[k] = 0 }
start = DateTime.parse('2014-03-01')
while start.strftime("%F") != '2014-05-01'
  days[get_day(start.strftime("%F"))] += 1
  start += 1
end

bus_stops =
  Hash.new do |stop, stop_id|
    stop[stop_id] =
      {
        on: { monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0, holiday: 0 },
        off: { monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0, holiday: 0 },
        outbound_distance: { monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0, holiday: 0 },
        inbound_distance: { monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0, holiday: 0 }
      }
  end

files = {
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_March1-15.rpt' => 4009146,
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_March16-31.rpt' => 4825079,
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_April1-15.rpt' => 4043147,
  '../SmartRiderJourney_March-April_2014/SmartRiderJourney_April15-30.rpt' => 3098661
}
files.each do |filename, length|
  bar = ProgressBar.new(filename, length)
  CSV.foreach(filename, headers: true) do |row|
    bar.inc
    next unless row['OnMode'] == '0'
    next if row['Distance'].to_f <= 0

    stop_id = row['OnLandmark'].to_i
    bus_stops[stop_id] ||= add_stop(stop_id)
    day = get_day(row['OnDate'])
    bus_stops[stop_id][:on][day] += 1

    bus_stops[stop_id][:outbound_distance][day] += row['Distance'].to_f

    stop_id = row['OffLandmark'].to_i
    bus_stops[stop_id] ||= add_stop(stop_id)
    day = get_day(row['OffDate'])
    bus_stops[stop_id][:off][day] += 1

    bus_stops[stop_id][:inbound_distance][day] += row['Distance'].to_f
  end
end

bus_stops.each do |stop_id, stop|
  stop[:on].each do |day, total|
    stop[:on][day] /= days[day].to_f
  end
  stop[:off].each do |day, total|
    stop[:off][day] /= days[day].to_f
  end
  stop[:outbound_distance].each do |day, total|
    next if stop[:outbound_distance][day] == 0
    stop[:outbound_distance][day] /= days[day].to_f
    stop[:outbound_distance][day] /= stop[:on][day]
  end
  stop[:inbound_distance].each do |day, total|
    next if stop[:inbound_distance][day] == 0
    stop[:inbound_distance][day] /= days[day].to_f
    stop[:inbound_distance][day] /= stop[:off][day]
  end
end

locations = {}
CSV.foreach("../stops.txt", headers: true) do |row|
  stop_id = row['stop_id'].to_i
  bus_stops[stop_id][:name] = row['stop_name']
  bus_stops[stop_id][:pos] = [row['stop_lat'].to_f, row['stop_lon'].to_f]
end

File.open("api/australia/states/WA/amenities/bus_stops.json", "w") { |f| f.write(JSON.pretty_generate(bus_stops)) }
