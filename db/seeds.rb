def clear_tables
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE sources,features,statistics,values,densities RESTART IDENTITY;")
end

SOURCE_ID = {}
def add_sources
  data = JSON.parse(File.read("api/australia/data_sources.json"))
  data.each do |source|
    sql = <<-SQL
      INSERT INTO sources (name, description)
      VALUES (
        '#{source["name"]}',
        '#{source["description"]}'
      );
    SQL
    ActiveRecord::Base.connection.execute(sql)
    SOURCE_ID[source['name']] = ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM sources;").to_a[0]["max"].to_i
  end
end

def get_source_id(source_name)
  SOURCE_ID[source_name]
end

def add_feature(type, name, location, postcode=nil, area=nil, polyline=nil)
  name = ActiveRecord::Base.connection.quote(name)
  lat, lng = location
  postcode ||= "NULL"
  area ||= "NULL"
  polyline = ActiveRecord::Base.connection.quote(polyline || "NULL")

  sql = <<-SQL
    INSERT INTO features (type, name, lat, lng, postcode, area, polyline)
    VALUES ('Suburb', #{name}, #{lat}, #{lng}, #{postcode}, #{area}, #{polyline});
  SQL

  ActiveRecord::Base.connection.execute(sql)
  ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM features;").to_a[0]["max"].to_i
end

def add_suburbs
  Dir.glob('api/australia/states/*/suburbs/*.json').each do |filename|
    next if filename =~ /(error|index)/
    add_suburb(filename)
  end
end

def add_suburb(filename)
  data = JSON.parse(File.read(filename))

  feature_id = add_feature('Suburb', data['suburb'], data['spatial']['pole'], data['postcode'], data['spatial']['area'], data['spatial']['poly'])

  add_population_statistics(feature_id, data['gender'], 'Gender')
  add_population_statistics(feature_id, data['age'], 'Age')
  add_population_statistics(feature_id, data['school_completed'], 'High School')
  add_population_statistics(feature_id, data['level_of_education'], 'Further Education')
  add_population_statistics(feature_id, data['qualifications'], 'Qualifications')
  add_population_statistics(feature_id, data['industry_of_employment'], 'Industry')
  add_population_statistics(feature_id, data['occupation'], 'Occupation')
  add_population_statistics(feature_id, data['travel_to_work'], 'Work Commute')
  add_population_statistics(feature_id, data['marital_status'], 'Marital Status')
  add_population_statistics(feature_id, data['country_of_birth'], 'Country of Birth')
  add_population_statistics(feature_id, data['languages_spoken'], 'Language')
  add_population_statistics(feature_id, data['religion'], 'Religion')
  add_population_statistics(feature_id, data['number_of_children'], 'Children')
  add_population_statistics(feature_id, data['internet_type'], 'Internet')

  return unless data = data['average_tax_return']
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Taxable Income', 'average', data['taxable_income'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Gross Tax', 'average', data['gross_tax'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Medicare Levy', 'average', data['medicare_levy'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'HELP Debt', 'average', data['help_debt'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Gross Interest', 'average', data['gross_interest'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Work Expenses', 'average', data['work_expenses'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Donations', 'average', data['donations'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Child Support', 'average', data['child_support'])
  add_value("Tax Return", "Suburb", feature_id, "Average", 'Gross Rent', 'average', data['gross_rent'])
end

POPULATION_NAME_MAP = {
}
def add_population_statistics(feature_id, data, heading)
  data.each do |name, count|
    name = POPULATION_NAME_MAP[name] || name
    add_value("Population", "Suburb", feature_id, heading, name, 'count', count)
  end
end

HEADING_ID =
  Hash.new do |sources, source_id|
    sources[source_id] =
      Hash.new do |features, feature_type|
        features[feature_type] = {}
      end
  end
def add_heading(source_id, feature_type, name)
  HEADING_ID[source_id][feature_type][name] ||=
    begin
      feature_type = ActiveRecord::Base.connection.quote(feature_type)
      name = ActiveRecord::Base.connection.quote(name)
      sql = <<-SQL
        INSERT INTO statistics (source_id, parent_id, name, feature_type, type)
        VALUES (#{source_id}, NULL, #{name}, #{feature_type}, NULL);
      SQL
      ActiveRecord::Base.connection.execute(sql)
      ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM statistics;").to_a[0]["max"].to_i
    end
end

MEASURE_ID =
  Hash.new do |sources, source_id|
    sources[source_id] =
      Hash.new do |headings, heading_id|
        headings[heading_id] =
          Hash.new do |features, feature_type|
            features[feature_type] = {}
          end
      end
  end
def add_measure(source_id, heading_id, feature_type, name, type)
  MEASURE_ID[source_id][heading_id][feature_type][name] ||=
    begin
      feature_type = ActiveRecord::Base.connection.quote(feature_type)
      name = ActiveRecord::Base.connection.quote(name)
      type = ActiveRecord::Base.connection.quote(type)
      sql = <<-SQL
        INSERT INTO statistics (source_id, parent_id, name, feature_type, type)
        VALUES (#{source_id}, #{heading_id}, #{name}, #{feature_type}, #{type});
      SQL
      ActiveRecord::Base.connection.execute(sql)
      ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM statistics;").to_a[0]["max"].to_i
    end
end

def add_value(source, feature_type, feature_id, heading, name, type, value)
  source_id = get_source_id(source)
  heading_id = add_heading(source_id, feature_type, heading)
  measure_id = add_measure(source_id, parent_id, feature_type, name, type)

  return if value <= 0

  sql = <<-SQL
    INSERT INTO values (statistic_id, feature_id, value)
    VALUES (#{measure_id}, #{feature_id}, #{value});
  SQL
  ActiveRecord::Base.connection.execute(sql)
end

# TODO: reprocess data to index by average per day
DAY_MAP = {
  'monday' => "Monday",
  'tuesday' => "Tuesday",
  'wednesday' => "Wednesday",
  'thursday' => "Thursday",
  'friday' => "Friday",
  'saturday' => "Saturday",
  'sunday' => "Sunday",
  'holiday' => "Public Holiday"
}
def add_bus_stops
  data = JSON.parse(File.read("api/australia/states/WA/amenities/bus_stops.json"))
  data.each do |day, stops|
    stops.each do |stop_id, data|
      next unless data['pos']
      name = "##{stop_id}: (#{data['name']})"
      feature_id = add_feature('Bus Stop', name, poll['location'])
      add_value("Bus Stops", "Bus Stop", feature_id, "Number Of", "Locations", 'bool', 1)
      add_value("Bus Stops", "Bus Stop", feature_id, "Tag Ons", DAY_MAP[day], 'count', data["on"])
      add_value("Bus Stops", "Bus Stop", feature_id, "Tag Offs", DAY_MAP[day], 'count', data["off"])
    end
  end
end

def add_polling_places
  data = JSON.parse(File.read("api/australia/states/WA/amenities/polling_places.json"))
  data.each do |name, poll|
    next unless poll['location']
    feature_id = add_feature('Polling Place', name, poll['location'])
    if poll["2008"]
      poll["2008"].each do |party, votes|
        add_value("Votes", "Polling Place", feature_id, '2008 Election', party, 'count', votes)
      end
    end
    if poll["2013"]
      poll["2013"].each do |party, votes|
        add_value("Votes", "Polling Place", feature_id, '2013 Election', party, 'count', votes)
      end
    end
  end
end

def add_childcare_centres
  data = JSON.parse(File.read("api/australia/states/WA/amenities/childcare_centres.json"))
  data.each do |centre|
    next unless centre['location']
    feature_id = add_feature('Child Care', centre['name'], centre['location')
    add_value("Childcare Centres", "Child Care", feature_id, "Number Of", "Locations", 'bool', 1)
    add_value("Childcare Centres", "Child Care", feature_id, "Number Of", "Children", 'count', centre['places'])
  end
end

def add_public_hospitals
  data = JSON.parse(File.read("api/australia/amenities/public_hospitals.json"))
  data.each do |hospital|
    next unless hospital['location']
    feature_id = add_feature('Hospital', hospital['name'], hospital['location'])
    add_value("Public Hospitals", "Hospital", feature_id, "Number Of", "Locations", 'bool', 1)
    add_value("Public Hospitals", "Hospital", feature_id, "Number Of", "Beds", 'count', hospital['beds'])
    add_value("Public Hospitals", "Hospital", feature_id, "That Have", "Emergency Dept.", 'bool', hospital['emergency'] ? 1 : 0)
  end
end

def add_public_toilets
  data = JSON.parse(File.read("api/australia/amenities/public_toilets.json"))
  data.each do |toilet|
    next unless toilet['location']
    feature_id = add_feature('Toilet', toilet['name'], toilet['location'])
    add_value("Public Toilets", "Toilet", feature_id, "Number Of", "Locations", 'bool', 1)
    add_value("Public Toilets", "Toilet", feature_id, "That Have", "Baby Change", 'bool', toilet['baby_change'] ? 1 : 0)
    add_value("Public Toilets", "Toilet", feature_id, "That Have", "Shower", 'bool', toilet['showers'] ? 1 : 0)
    add_value("Public Toilets", "Toilet", feature_id, "That Have", "Drinking Water", 'bool', toilet['drinking_water'] ? 1 : 0)
    add_value("Public Toilets", "Toilet", feature_id, "That Have", "Sharps Disposal", 'bool', toilet['sharps_disposal'] ? 1 : 0)
    add_value("Public Toilets", "Toilet", feature_id, "That Have", "Sanitary Disposal", 'bool', toilet['sanitary_disposal'] ? 1 : 0)
  end
end

def create_densities
  sql = <<-SQL
    INSERT INTO densities (id, statistic_id, feature_id, density)
    SELECT id, statistic_id, feature_id, value
    FROM values
    ;
  SQL
  ActiveRecord::Base.connection.execute(sql)
  ActiveRecord::Base.connection.execute("SELECT id FROM statistics;").to_a.each do |statistic|
    sql = <<-SQL
      SELECT MAX(value)
      FROM values
      WHERE statistic_id=#{statistic["id"]}
      ;
    SQL
    maximum = ActiveRecord::Base.connection.execute(sql).to_a[0]["max"].to_f
    sql = <<-SQL
      UPDATE densities
        SET density=density/#{maximum}
        WHERE statistic_id=#{statistic["id"]}
      ;
    SQL
    ActiveRecord::Base.connection.execute(sql)
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
create_densities
