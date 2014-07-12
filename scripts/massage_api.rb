#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

Dir.glob("new_api/**/") do |dir|
  contents = Dir.glob("#{dir}*").to_a
  index = {
    size: contents.length,
    endpoints: contents.map { |f| f.gsub('new_api', '') }.sort { |f| }
  }
  File.open("#{dir}index.json", "w") { |f| f.write(JSON.pretty_generate(index)) }
end

