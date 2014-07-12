def clear_tables
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE sources,features,statistics,values,densities RESTART IDENTITY;")
end

def add_sources
  data = JSON.parse(File.read("api/sources.json"))
  data.each do |source|
    sql = <<-SQL
      INSERT INTO sources (name, description) VALUES ('#{source["name"]}', '#{source["description"]}');
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

#clear_tables
#add_sources
add_suburbs
add_bus_stops
add_polling_places
add_childcare_centres
add_public_hospitals
add_public_toilets
