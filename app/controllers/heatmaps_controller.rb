class HeatmapsController < ApplicationController
  def index
  end

  def filters
    render json: _get_filters
  end

  def points
    render json: {}
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
    retval = {}
    ActiveRecord::Base::connection.execute(sql).each do |item|
      retval[item['source_name']] ||=
        {
          id: item['source_id'].to_i,
          topics: {}
        }
      if item['parent_id'].nil?
        retval[item['source_name']][:topics][item['statistic_id'].to_i] =
          {
            name: item['statistic_name'],
            statistics: {}
          }
      else
        retval[item['source_name']][:topics][item['parent_id'].to_i][:statistics][item['statistic_id'].to_i] = item['statistic_name']
      end
    end
    retval
  end
end
