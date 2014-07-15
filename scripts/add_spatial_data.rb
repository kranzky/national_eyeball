#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'open-uri'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

def get_area(kml_blob)
  0
end

POSTCODES = JSON.parse(File.read('../combined.json'))
def get_postcode(state, suburb)
  return unless entry = POSTCODES[suburb]
  return unless data = entry['locations'].find { |l| l['div_s'] == state }
  data['postcode'].to_i
end

def get_pole_of_inaccessibility(latlngs)
  poly = Sangaku::Polygon.new(*latlngs)
  poly.close!
  aabb = poly.aabb
  aabb.square!
  aabb *= 1.1
  stars = nil
  20.times do
    grid = aabb.to_grid(13)
    stars = grid.get_stars(poly)
    return nil if stars.sort.first.nil?
    aabb.centre!(stars.sort.first.center)
    aabb *= 0.83
  end
  stars.sort.first.center.to_a
end

def encode_polylines(latlngs)
  Polylines::Encoder.encode_points(latlngs)
end

def process_suburb(abs_data)
  data = JSON.parse(File.read(abs_data))
  return unless data['suburb']
  return if data['spatial']
  filename = "../aus_suburb_kml/#{data['state']}/#{data['suburb']}.kml"
  return unless File.exists?(filename)
  blob = File.read(filename)
  return unless coords = /\<coordinates\>(.*)\<\/coordinates\>/.match(blob)[1]
  latlngs = coords.split.map { |point| point.split(',').map(&:to_f).reverse }
  pole = get_pole_of_inaccessibility(latlngs)
  area = get_area(blob)
  poly = encode_polylines(latlngs)
  data[:spatial] = {
    pole: pole,
    area: area,
    poly: poly
  }
  data[:postcode] = get_postcode(data['state'], data['suburb'])
  File.open(abs_data, "w") { |f| f.write(JSON.pretty_generate(data)) }
end

Dir.glob("./api/australua/states/*/suburbs/*.json").each do |filename|
  next if filename =~ /(index|error)/
  process_suburb(filename)
end
