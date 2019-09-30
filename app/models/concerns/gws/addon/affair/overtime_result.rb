module Gws::Addon::Affair::OvertimeResult
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_results

    embeds_many :results, class_name: "Gws::Affair::OvertimeResult"
    field :results_by_day, type: Array

    permit_params in_results: [ :start_at, :end_at, :capital_id ]

    before_validation :set_results, if: -> { in_results.present? }
    before_save :set_results_by_day
  end

  module ClassMethods
    def aggregate_results_by_date(unit = "day")
      match_pipeline = self.criteria.selector
      project_pipeline = { results_by_day: 1 }
      group_pipeline = {
        _id: {
          year: { "$year" => "$results_by_day.date" },
        },
        minute: { "$sum" => "$results_by_day.minute" }
      }

      if unit == "day"
        group_pipeline[:_id][:month] = { "$month" => "$results_by_day.date" }
        group_pipeline[:_id][:day] = { "$dayOfMonth" => "$results_by_day.date" }
      elsif unit == "month"
        group_pipeline[:_id][:month] = { "$month" => "$results_by_day.date" }
      end

      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$project" => project_pipeline }
      pipes << { "$unwind" => "$results_by_day" }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => { "_id.year" => 1 , "_id.month" => 1, "_id.day" => 1 } }

      prefs = {}
      aggregation = self.collection.aggregate(pipes)

      if unit == "day"
        aggregation.each do |i|
          year = i["_id"]["year"]
          month = i["_id"]["month"]
          day = i["_id"]["day"]

          prefs[year] ||= {}
          prefs[year][month] ||= {}
          prefs[year][month][day] = i["minute"]
        end
      elsif unit == "month"
        aggregation.each do |i|
          year = i["_id"]["year"]
          month = i["_id"]["month"]

          prefs[year] ||= {}
          prefs[year][month] = i["minute"]
        end
      else
        aggregation.each do |i|
          year = i["_id"]["year"]

          prefs[year] = i["minute"]
        end
      end
      prefs
    end

    def aggregate_results_by_capital(unit = "day")
      match_pipeline = self.criteria.selector
      project_pipeline = { results_by_day: 1 }
      group_pipeline = {
        _id: {
          capital_id: "$results_by_day.capital_id"
        },
        minute: { "$sum" => "$results_by_day.minute" }
      }

      if unit == "day"
        group_pipeline[:_id][:year] = { "$year" => "$results_by_day.date" }
        group_pipeline[:_id][:month] = { "$month" => "$results_by_day.date" }
      elsif unit == "month"
        group_pipeline[:_id][:year] = { "$year" => "$results_by_day.date" }
      end

      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$project" => project_pipeline }
      pipes << { "$unwind" => "$results_by_day" }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => { "_id.year" => 1 , "_id.month" => 1, "_id.day" => 1 } }

      prefs = {}
      aggregation = self.collection.aggregate(pipes)

      if unit == "day"
        aggregation.each do |i|
          capital_id = i["_id"]["capital_id"]
          year = i["_id"]["year"]
          month = i["_id"]["month"]

          prefs[year] ||= {}
          prefs[year][month] ||= {}
          prefs[year][month][capital_id] = i["minute"]
        end
      elsif unit == "month"
        aggregation.each do |i|
          capital_id = i["_id"]["capital_id"]
          year = i["_id"]["year"]

          prefs[year] ||= {}
          prefs[year][capital_id] = i["minute"]
        end
      else
        aggregation.each do |i|
          capital_id = i["_id"]["capital_id"]

          prefs[capital_id] = i["minute"]
        end
      end
      prefs
    end
  end

  def set_results
    items = []
    in_results.each do |result|
      next if result["start_at"].blank?
      next if result["end_at"].blank?
      next if result["capital_id"].blank?

      affair_start = site.affair_start(start_at)

      s_at = Time.zone.parse(start_at.strftime("%Y/%m/%d") + " #{result["start_at"]}")
      if s_at < affair_start
        s_at = s_at.advance(days: 1)
      end

      e_at = Time.zone.parse(s_at.strftime("%Y/%m/%d") + " #{result["end_at"]}")
      if e_at < affair_start
        e_at = e_at.advance(days: 1)
      end

      item = Gws::Affair::OvertimeResult.new
      item.start_at = s_at
      item.end_at = e_at
      item.capital_id = result["capital_id"]
      items << item
    end

    self.results = items
  end

  def set_results_by_day
    h = {}
    results.each do |result|
      s_at = result.start_at
      e_at = result.end_at

      t_day = start_at.advance(days: 1).strftime("%Y/%m/%d")
      t_hour = " #{site.attendance_time_changed_minute.to_i / 60}:00"
      t_at = Time.zone.parse(t_day + t_hour).to_datetime

      if e_at < t_at
        key = [start_at.to_date, result.capital_id]
        h[key] ||= 0
        h[key] += ((e_at - s_at) * 24 * 60).to_i
      else
        key = [start_at.to_date, result.capital_id]
        h[key] ||= 0
        h[key] += ((t_at - s_at) * 24 * 60).to_i

        key = [t_at.to_date, result.capital_id]
        h[key] ||= 0
        h[key] += ((e_at - t_at) * 24 * 60).to_i
      end
    end

    self.results_by_day = h.map do |key, minute|
      date, capital_id = key
      {
        date: date,
        capital_id: capital_id,
        minute: minute
      }
    end
  end

  def results_start_at
    result = results.first
    result.try(:start_at)
  end

  def results_end_at
    result = results.last
    result.try(:end_at)
  end
end
