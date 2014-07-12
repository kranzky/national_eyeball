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
  add_statistic("ABS", "Suburb", feature_id, heading, nil, data.values.reduce(0, :+))
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
        (SELECT id FROM statistics WHERE name='#{heading}' AND parent_id IS NULL),
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
  statistic_id = ActiveRecord::Base.connection.execute(sql).to_a[0]["id"].to_i

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
  data = JSON.parse(File.read("api/bus_stops.json"))
  data.each do |month, stops|
    stops.each do |stop_id, data|
      name = "#{stop_id}: (#{data['name']})"
      next unless data["pos"]
      INSERTED[name] += 1
      if INSERTED[name] == 1
        sql = <<-SQL
          INSERT INTO features (type, name, lat, lng)
          VALUES (
            'Bus Stop',
            #{ActiveRecord::Base.connection.quote(name)},
            #{data["pos"][0]},
            #{data["pos"][1]}
          );
        SQL
        ActiveRecord::Base.connection.execute(sql)
      end
      sql = <<-SQL
        SELECT id FROM features
          WHERE name=#{ActiveRecord::Base.connection.quote(name)}
        ;
      SQL
      feature_id = ActiveRecord::Base.connection.execute(sql).to_a[0]["id"].to_i
      heading =
        case month
        when "march"
          "March 2014"
        when "april"
          "April 2014"
        end
      add_statistic("PTA", "Bus Stop", feature_id, heading, nil, 1)
      add_statistic("PTA", "Bus Stop", feature_id, heading, "Tag On", data["on"])
      add_statistic("PTA", "Bus Stop", feature_id, heading, "Tag Off", data["off"])
    end
  end
end

def add_polling_places
  data = JSON.parse(File.read("api/polling_places.json"))
  data.each do |name, poll|
    next if poll["location"][0] == 0.0
    next if poll["location"][1] == 0.0
    sql = <<-SQL
      INSERT INTO features (type, name, lat, lng)
      VALUES (
        'Polling Place',
        #{ActiveRecord::Base.connection.quote(name)},
        #{poll["location"][0]},
        #{poll["location"][1]}
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)
    feature_id = ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM features;").to_a[0]["max"].to_i
    if poll["2008"]
      add_statistic("WAEC", "Polling Place", feature_id, "2008", nil, poll["2008"].values.reduce(0, :+))
      poll["2008"].each do |party, votes|
        add_statistic("WAEC", "Polling Place", feature_id, "2008", party, votes)
      end
    end
    if poll["2013"]
      add_statistic("WAEC", "Polling Place", feature_id, "2013", nil, poll["2013"].values.reduce(0, :+))
      poll["2013"].each do |party, votes|
        add_statistic("WAEC", "Polling Place", feature_id, "2013", party, votes)
      end
    end
  end
end

def add_childcare_centres
  data = JSON.parse(File.read("api/childcare_centres.json"))
  data.each do |centre|
    next unless centre['location']
    sql = <<-SQL
      INSERT INTO features (type, name, lat, lng)
      VALUES (
        'Child Care',
        #{ActiveRecord::Base.connection.quote(centre['name'])},
        #{centre["location"][0]},
        #{centre["location"][1]}
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)
    feature_id = ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM features;").to_a[0]["max"].to_i
    add_statistic("DOE", "Child Care", feature_id, "Locations", nil, 1)
    add_statistic("DOE", "Child Care", feature_id, "Locations", "Capacity", centre['places'])
  end
end

def add_public_hospitals
  data = JSON.parse(File.read("api/public_hospitals.json"))
  data.each do |hospital|
    next unless hospital['location']
    sql = <<-SQL
      INSERT INTO features (type, name, lat, lng)
      VALUES (
        'Hospital',
        #{ActiveRecord::Base.connection.quote(hospital['name'])},
        #{hospital["location"][0]},
        #{hospital["location"][1]}
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)
    feature_id = ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM features;").to_a[0]["max"].to_i
    add_statistic("AIHW", "Hospital", feature_id, "Locations", nil, 1)
    add_statistic("AIHW", "Hospital", feature_id, "Locations", "Beds", hospital['beds'])
    add_statistic("AIHW", "Hospital", feature_id, "Locations", "Emergency", hospital['emergency'] ? 1 : 0)
  end
end

def add_public_toilets
  data = JSON.parse(File.read("api/public_toilets.json"))
  data.each do |toilet|
    next unless toilet['location']
    sql = <<-SQL
      INSERT INTO features (type, name, lat, lng)
      VALUES (
        'Toilet',
        #{ActiveRecord::Base.connection.quote(toilet['name'])},
        #{toilet["location"][0]},
        #{toilet["location"][1]}
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)
    feature_id = ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM features;").to_a[0]["max"].to_i
    add_statistic("DoHA", "Toilet", feature_id, "Locations", nil, 1)
    next unless toilet = toilet['features']
    add_statistic("DoHA", "Toilet", feature_id, "Locations", "Baby Change", toilet['baby_change'] ? 1 : 0)
    add_statistic("DoHA", "Toilet", feature_id, "Locations", "Shower", toilet['showers'] ? 1 : 0)
    add_statistic("DoHA", "Toilet", feature_id, "Locations", "Drinking Water", toilet['drinking_water'] ? 1 : 0)
    add_statistic("DoHA", "Toilet", feature_id, "Locations", "Sharps Disposal", toilet['sharps_disposal'] ? 1 : 0)
    add_statistic("DoHA", "Toilet", feature_id, "Locations", "Sanitary Disposal", toilet['sanitary_disposal'] ? 1 : 0)
  end
end

clear_tables
add_sources
add_suburbs
add_bus_stops
add_polling_places
add_childcare_centres
add_public_hospitals
add_public_toilets
