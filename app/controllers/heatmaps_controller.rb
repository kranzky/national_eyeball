class HeatmapsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
  end

  def filters
    render json: _get_filters
  end

  def points
    render json: _get_points
  end

  def comments
    render json: _get_comments
  end

  private

  def _get_filters
    sql = <<-SQL
      SELECT sources.id AS source_id,
             sources.name AS source_name,
             parent.id AS parent_id,
             parent.name AS parent_name,
             statistics.id AS statistic_id,
             statistics.name AS statistic_name
      FROM statistics
        INNER JOIN sources ON source_id=sources.id
        LEFT JOIN statistics AS parent ON statistics.parent_id=parent.id
      ;
    SQL
    retval = { menu: {}, lookup: {} }
    ActiveRecord::Base::connection.execute(sql).each do |item|
      retval[:menu][item['source_id'].to_i] ||=
        {
          name: item['source_name'],
          menu: {}
        }
      if item['parent_id'].nil?
        retval[:menu][item['source_id'].to_i][:menu][item['statistic_id'].to_i] =
          {
            name: item['statistic_name'],
            menu: {}
          }
      else
        retval[:menu][item['source_id'].to_i][:menu][item['parent_id'].to_i][:menu][item['statistic_id'].to_i] = { name: item['statistic_name'] }
      end
      retval[:lookup][item['statistic_id'].to_i] = [item['source_id'].to_i, item['parent_id'].to_i]
    end
    retval
  end

  def _get_points
    params[:filters].map do |filter_id|
      sql = <<-SQL
        SELECT lat,lng,density,statistics.type FROM densities
          INNER JOIN statistics ON statistic_id=statistics.id
          INNER JOIN features ON feature_id=features.id
          WHERE statistic_id=#{filter_id}
          AND #{_get_spatial_constraint}
          ORDER BY density desc,RANDOM()
          LIMIT 250
        ;
      SQL
      ActiveRecord::Base::connection.execute(sql).map do |item|
        {
          type: item['type'],
          lat: item['lat'].to_f,
          lng: item['lng'].to_f,
          weight: item['density'].to_f
        }
      end
    end
  end

  COMMENT_TEMPLATES = {
    "Population" => {
      "Gender" => "Number of %s",
      "Age" => "People Aged %s",
      "High School" => "People who %s",
      "Further Education" => "People with a %s",
      "Qualifications" => "People Qualified in %s",
      "Industry" => "People Working in %s",
      "Occupation" => "People Employed as a %s",
      "Work Commute" => "People who Commute by %s",
      "Children" => "Homes with %s",
      "Marital Status" => "Adults who are %s",
      "Country of Birth" => "People who were born in %s",
      "Language" => "People who speak %s",
      "Religion" => "People that are %s",
      "Internet" => {
        "None" => "Homes without Internet",
        "Broadband" => "Homes with Broadband Internet",
        "Dial up" => "Homes with Dial Up Internet",
        "Other" => "Homes with Other Internet Access",
      }
    },
    "Public Hospitals" => {
      "Number Of" => {
        "Locations" => "Public Hospitals",
        "Beds" => "Number of Hospital Beds"
      },
      "That Have" => "Hospitals with Emergency Services"
    },
    "Votes" => {
      "2008 Election" => "Primary Votes in 2008 for %s",
      "2013 Election" => "Primary Votes in 2013 for %s"
    },
    "Bus Stops" => {
      "Number Of" => "Bus Stops",
      "Tagged On" => "Bus Entries on %ss",
      "Tagged Off" => "Bus Exits on %ss",
      "Average Outbound Distance" => "Bus Outwards Journey on %ss",
      "Average Inbound Distance" => "Bus Inwards Journey on %ss"
    },
    "Childcare Centres" => {
      "Number Of" => {
        "Locations" => "Childcare Centres",
        "Children" => "Number of Children in Childcare"
      }
    },
    "Public Toilets" => {
      "Number Of" => "Public Toilets",
      "That Have" => "Public Toilets with %s"
    },
    "Tax Return" => "Average %s"
  }
  COUNT_TEMPLATES = {
    "Bus Stops" => {
      "Average Outbound Distance" => "%s km",
      "Average Inbound Distance" => "%s km"
    },
    "Tax Return" => "$%s"
  }
  MEASURE_MAP = {
    "Shower" => "a Shower",
    "Public Holiday" => "Holiday",
    "(none)" => "No Party",
    "Gross Interest" => "Interest on Savings",
    "Donations" => "Donations to Charity",
    "Child Support" => "Child Support Payment",
    "Gross Rent" => "Rental Income",
    "Male" => "Men",
    "Female" => "Women",
    "0 - 4 years" => "0 - 4",
    "5 - 14 years" => "5 - 14",
    "15 - 19 years" => "15 - 19",
    "20 - 24 years" => "20 - 24",
    "25 - 34 years" => "25 - 34",
    "35 - 44 years" => "35 - 44",
    "45 - 54 years" => "45 - 54",
    "55 - 64 years" => "55 - 64",
    "65 - 74 years" => "65 - 74",
    "75 - 84 years" => "75 - 84",
    "85 years and over" => "85 and Over",
    "Year 12 or equivalent" => "Graduated High School",
    "Year 11 or equivalent" => "Left School at Year 11",
    "Year 10 or equivalent" => "Left School at Year 10",
    "Year 9 or equivalent" => "Left School at Year 9",
    "Year 8 or below" => "Left School Before Year 9",
    "Did not go to school" => "Never Attended School",
    "Graduate Diploma and Graduate Certificate" => "Graduate Diploma",
    "Advanced Diploma and Diploma" => "Diploma",
    "Other Certificate" => "Certificate",
    "Natural and Physical Sciences" => "the Sciences",
    "Information Technology" => "IT",
    "Engineering and Related Technologies" => "Engineering",
    "Architecture and Building" => "Architecture",
    "Agriculture Environmental and Related Studies" => "Agriculture",
    "Management and Commerce" => "Business",
    "Food Hospitality and Personal Services" => "Hospitality",
    "Mixed Field Programmes" => "Other Areas",
    "Agriculture forestry and fishing" => "Agriculture",
    "Electricity gas water and waste services" => "Utility Services",
    "Wholesale trade" => "Wholesale Trade",
    "Retail trade" => "Retail",
    "Accommodation and food services" => "Hospitality",
    "Transport postal and warehousing" => "Transport",
    "Information media and telecommunications" => "Telecommunications",
    "Financial and insurance services" => "Finance and Insurance",
    "Rental hiring and real estate services" => "Real Estate",
    "Professional scientific and technical services" => "Scientific Roles",
    "Administrative and support services" => "Administration",
    "Public administration and safety" => "the Public Service",
    "Education and training" => "Education",
    "Health care and social assistance" => "Health Care",
    "Arts and recreation services" => "the Arts",
    "Technician / Trade" => "Technician",
    "Community / Personal Service" => "Service Worker",
    "Clerical / Administrative" => "Clerical Worker",
    "Sales" => "Sales Person",
    "Machinery Operator / Driver" => "Machinery Operator",
    "Car as driver" => "Car",
    "Car as passenger" => "Getting a Lift",
    "Motorbike scooter" => "Motorbike",
    "Walked only" => "Walking",
    "Train and Car as driver" => "Train and Car",
    "Train and Car as passenger" => "Train and a Lift",
    "Bus and Car as driver" => "Bus and Car",
    "Bus and Car as passenger" => "Bus and a Lift",
    "Worked at home" => "Not Moving",
    "Did not go to work" => "Not Working",
    "Never Married" => "Not Married",
    "Buddhism" => "Buddhist",
    "Churches of Christ" => "Church of Christ",
    "Hinduism" => "Hindu",
    "Islam" => "Islamic",
    "Judaism" => "Jewish",
    "No Religion" => "Not Religious",
    "One child" => "One Child",
    "Two children" => "Two Children",
    "Three children" => "Three Children",
    "Four children" => "Four Children",
    "Five children" => "Five Children",
    "Six or more children" => "Six Children or More",
  }
  def _get_comments
    params[:filters].map do |filter_id|
      sql = <<-SQL
        SELECT SUM(value) AS total,statistics.type AS type,count(*) AS count FROM values
          INNER JOIN statistics ON statistic_id=statistics.id
          INNER JOIN features ON feature_id=features.id
          WHERE statistic_id=#{filter_id}
          AND #{_get_spatial_constraint}
          GROUP BY statistics.type
        ;
      SQL
      total = 0
      if result = ActiveRecord::Base::connection.execute(sql).first
        total = result["total"].to_f
        total /= result["count"].to_f if result["type"] == "average"
      end
      sql = <<-SQL
        SELECT sources.name AS source,
               topics.name AS subject,
               statistics.name AS measure
        FROM statistics
          INNER JOIN sources ON sources.id=source_id
          LEFT JOIN statistics AS topics ON topics.id=statistics.parent_id
          WHERE statistics.id=#{filter_id}
        ;
      SQL
      labels = ActiveRecord::Base::connection.execute(sql).first
      template = COMMENT_TEMPLATES[labels['source']]
      template = template[labels['subject']] if template.is_a?(Hash)
      template = template[labels['measure']] if template.is_a?(Hash)
      measure = labels['measure']
      measure = MEASURE_MAP[measure] || measure
      comment = template % measure if template.is_a?(String)
      comment ||= "#{labels['source']}: #{labels['subject']} #{labels['measure']}"
      precision = total < 1000 ? 2 : 0
      count = number_with_precision(total, precision: precision, strip_insignificant_zeros: true, delimiter: ',')
      template = COUNT_TEMPLATES[labels['source']]
      template = template[labels['subject']] if template.is_a?(Hash)
      template = template[labels['measure']] if template.is_a?(Hash)
      count = template % count if template.is_a?(String)
      {
        comment: comment,
        count: count
      }
    end
  end

  def _get_spatial_constraint
    bounds = params[:bounds].map(&:to_f)
    return <<-SQL
      (
        (lat BETWEEN #{bounds[0]} AND #{bounds[2]})
        AND
        (
          #{bounds[1]} < #{bounds[3]} AND lng BETWEEN #{bounds[1]} AND #{bounds[3]}
          OR
          (
            #{bounds[1]} >= #{bounds[3]}
            AND
            (
              lng BETWEEN #{bounds[1]} AND 180
              OR
              lng BETWEEN -180 AND #{bounds[3]}
            )
          )
        )
      )
    SQL
  end
end
