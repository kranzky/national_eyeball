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
    endpoints: contents.map { |f| f.gsub('new_api', '') }
  }
  File.open("#{dir}index.json", "w") { |f| f.write(JSON.pretty_generate(index)) }
  error = {
    error: "bad luck; try: #{dir.gsub('new_api', '')}index.json"
  }
  File.open("#{dir}error.json", "w") { |f| f.write(JSON.pretty_generate(error)) }
end

