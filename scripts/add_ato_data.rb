#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'open-uri'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

ATO = JSON.parse(File.read('ato.json'))
def add_ato(filename)
  data = JSON.parse(File.read(filename))
  return unless data['state']
  return unless data['suburb']
  return unless data['postcode']
  return unless tax_data = ATO[data['postcode'].to_s]
  data['average_tax_return'] = tax_data
  File.open(filename, "w") { |f| f.write(JSON.pretty_generate(data)) }
end

bar = ProgressBar.new("doing", 8511)
Dir.glob("./api/**/statistics.json").each do |filename|
  bar.inc
  add_ato(filename)
end
