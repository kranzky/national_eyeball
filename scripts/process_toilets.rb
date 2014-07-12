#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

doc = Nokogiri::XML(File.read('../ToiletmapExport_140701_090000.xml'))
toilets =
  doc.css('ToiletDetails').map do |toilet|
    {
      name: toilet.css('Name').text,
      location: [toilet['Latitude'], toilet['Longitude']],
      features: {
        baby_change: toilet.css('Features').css('BabyChange').text == "true",
        showers: toilet.css('Features').css('Showers').text == "true",
        drinking_water: toilet.css('Features').css('DrinkingWater').text == "true",
        sharps_disposal: toilet.css('Features').css('SharpsDisposal').text == "true",
        sanitary_disposal: toilet.css('Features').css('SanitaryDisposal').text == "true"
      }
    }
  end

File.open("toilets.json", "w") { |f| f.write(JSON.pretty_generate(toilets)) }
