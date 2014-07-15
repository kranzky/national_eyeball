#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

Dir.glob("api/**/") do |dir|
  contents = Dir.glob("#{dir}*").to_a
  index = {
    size: contents.length,
    endpoints: contents.map { |f| f.gsub('new_api', '') }
  }
  File.open("#{dir}index.json", "w") { |f| f.write(JSON.pretty_generate(index)) }
  error = {
    error: "bad luck; try: #{dir.gsub('api', '')}index.json"
  }
  File.open("#{dir}error.json", "w") { |f| f.write(JSON.pretty_generate(error)) }
end

