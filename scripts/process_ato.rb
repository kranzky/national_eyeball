#!/usr/bin/env ruby

require 'json'
require 'csv'

require 'rubygems'
require 'bundler'

Bundler.require(:development)

ato = Hash.new { |h, k| h[k] = {} }
CSV.foreach("../taxstats2012individual06aselecteditemsbystateandpostcode.csv", headers: true) do |row|
  total = row["Number of individuals no."].gsub(',', '').to_f
  ato[row['Postcode'].to_i] =
    {
      taxable_income: row['Taxable income or loss $'].gsub(',', '').to_f / total,
      gross_tax: row['Gross tax $'].gsub(',', '').to_f / total,
      medicare_levy: row['Medicare levy $'].gsub(',', '').to_f / total,
      help_debt: row['HELP assessment debt $'].gsub(',', '').to_f / total,
      gross_interest: row['Gross interest $'].gsub(',', '').to_f / total,
      work_expenses: row['Total work related expenses $'].gsub(',', '').to_f / total,
      donations: row['Gifts or donations $'].gsub(',', '').to_f / total,
      child_support: row['Child support you paid $'].gsub(',', '').to_f / total,
      gross_rent: row['Gross rent $'].gsub(',', '').to_f / total,
    }
end

File.open("../ato.json", "w") { |f| f.write(JSON.pretty_generate(ato)) }
