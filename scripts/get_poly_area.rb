#!/usr/bin/env ruby

require 'json'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

def process_suburb(abs_data)
  data = JSON.parse(File.read(abs_data))
  return unless data['spatial']
  {
    file: abs_data,
    poly: data['spatial']['poly']
  }
end

blob = []
Dir.glob("./api/australia/states/*/suburbs/*.json").each do |filename|
  next if filename =~ /(index|error)/
  blob << process_suburb(filename)
end
File.open("blob", "w") { |f| f.write(blob.compact.to_json) }
