class HeatmapsController < ApplicationController
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
      "Age" => "People who are aged %s",
      "Gender" => "People who are %s",
      "Children" => "Adults with %s",
      "Marital Status" => "Adults who are %s",
      "Country of Birth" => "People who were born in %s",
      "Language" => "People who speak %s",
    },
    "Childcare Centres" => {
      "Number Of" => {
        "Children" => "Number of children in childcare"
      }
    }
  }
  def _get_comments
    params[:filters].map do |filter_id|
      sql = <<-SQL
        SELECT SUM(value) AS total FROM values
          INNER JOIN statistics ON statistic_id=statistics.id
          INNER JOIN features ON feature_id=features.id
          WHERE statistic_id=#{filter_id}
          AND #{_get_spatial_constraint}
        ;
      SQL
      total = ActiveRecord::Base::connection.execute(sql).first["total"]
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
      comment = template % labels['measure'].downcase if template.is_a?(String)
      comment ||= "#{labels['source']}: #{labels['subject']} #{labels['measure']}"
      {
        comment: comment,
        count: total || 0
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
