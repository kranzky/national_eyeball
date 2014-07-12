def clear_tables
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE sources,features,statistics,values,densities RESTART IDENTITY;")
end

def add_sources
  data = JSON.parse(File.read("api/sources.json"))
  data.each do |source|
    sql = <<-SQL
      INSERT INTO sources (name, description)
      VALUES (
        '#{source["name"]}',
        '#{source["description"]}'
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end
end

def add_suburbs
  Dir.glob('api/**/statistics.json').each do |filename|
    add_suburb(filename)
  end
end

def add_suburb(filename)
  data = JSON.parse(File.read(filename))

  sql = <<-SQL
    INSERT INTO features (type, name, lat, lng, postcode, area, polyline)
    VALUES (
      'Suburb',
      #{ActiveRecord::Base.connection.quote(data["suburb"])},
      #{data["spatial"]["pole"][0]},
      #{data["spatial"]["pole"][1]},
      #{data["postcode"]},
      #{data["spatial"]["area"]},
      #{ActiveRecord::Base.connection.quote(data["spatial"]["poly"])}
    );
  SQL
  ActiveRecord::Base.connection.execute(sql)

  feature_id = ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM features;").to_a[0]["max"].to_i

  add_abs_statistics(feature_id, data['gender'], 'Gender')
  add_abs_statistics(feature_id, data['age'], 'Age')
  add_abs_statistics(feature_id, data['school_completed'], 'Level of School Completed')
  add_abs_statistics(feature_id, data['level_of_education'], 'Further Education')
  add_abs_statistics(feature_id, data['qualifications'], 'Qualifications')
  add_abs_statistics(feature_id, data['industry_of_employment'], 'Industry of Employment')
  add_abs_statistics(feature_id, data['occupation'], 'Occupation')
  add_abs_statistics(feature_id, data['travel_to_work'], 'Work Commute')
  add_abs_statistics(feature_id, data['marital_status'], 'Marital Status')
  add_abs_statistics(feature_id, data['country_of_birth'], 'Country of Birth')
  add_abs_statistics(feature_id, data['languages_spoken'], 'Languages Spoken')
  add_abs_statistics(feature_id, data['religion'], 'Religion')
  add_abs_statistics(feature_id, data['number_of_children'], 'Number of Children')
  add_abs_statistics(feature_id, data['internet_type'], 'Type of Internet Connection')

  return unless data = data['average_tax_return']
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", nil, 1)
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Taxable Income', data['taxable_income'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Gross Tax', data['gross_tax'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Medicare Levy', data['medicare_levy'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'HELP Debt', data['help_debt'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Gross Interest', data['gross_interest'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Work Expenses', data['work_expenses'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Donations', data['donations'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Child Support', data['child_support'])
  add_statistic("ATO", "Suburb", feature_id, "Taxpayer Average", 'Gross Rent', data['gross_rent'])
end

def add_abs_statistics(feature_id, data, heading)
  add_statistic("ABS", "Suburb", feature_id, heading, nil, data.values.reduce(:+))
  data.each do |name, count|
    add_statistic("ABS", "Suburb", feature_id, heading, name, count)
  end
end

INSERTED = Hash.new { |h, k| h[k] = 0 }
def add_statistic(source, feature, feature_id, heading, name, value)
  return if value <= 0
  key = [source, feature, heading, name || ""].join('|')
  INSERTED[key] += 1
  if INSERTED[key] == 1
    sql = <<-SQL
      INSERT INTO statistics (source_id, parent_id, name, feature_type)
      VALUES (
        (SELECT id FROM sources WHERE name='#{source}'),
        (SELECT id FROM statistics WHERE name='#{heading}'),
        #{ActiveRecord::Base.connection.quote(name || heading)},
        #{ActiveRecord::Base.connection.quote(feature)}
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  sql = <<-SQL
    SELECT id FROM statistics
      WHERE feature_type='#{feature}'
        AND source_id IN (SELECT id FROM sources WHERE name='#{source}')
        AND name='#{name || heading}'
        AND (parent_id IS NULL OR parent_id IN (SELECT id FROM statistics WHERE name='#{heading}'))
    ;
  SQL
  statistic_id = ActiveRecord::Base.connection.execute(sql).to_a[0]["max"].to_i

  sql = <<-SQL
    INSERT INTO values (statistic_id, feature_id, value)
    VALUES (
      #{statistic_id},
      #{feature_id},
      #{value}
    );
  SQL
  ActiveRecord::Base.connection.execute(sql)
end

def add_bus_stops
end

def add_polling_places
end

def add_childcare_centres
end

def add_public_hospitals
end

def add_public_toilets
end

clear_tables
add_sources
add_suburbs
add_bus_stops
add_polling_places
add_childcare_centres
add_public_hospitals
add_public_toilets
