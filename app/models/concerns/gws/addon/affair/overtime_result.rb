module Gws::Addon::Affair::OvertimeResult
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_results
    permit_params in_results: {}

    embeds_one :result, class_name: "Gws::Affair::OvertimeResult"
  end

  module ClassMethods
    def aggregate_results_by_timecard
      match_pipeline = self.criteria.selector
      project_pipeline = { results_by_day: 1 }
      group_pipeline = {
          _id: {
              date: "$results_by_day.date"
          },
          minute: { "$sum" => "$results_by_day.minute" },
          file_ids: { "$push" => "$_id" }
      }
      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$project" => project_pipeline }
      pipes << { "$unwind" => "$results_by_day" }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => { "_id.date" => 1 } }

      prefs = {}
      aggregation = self.collection.aggregate(pipes)
      aggregation.each do |i|
        date = i["_id"]["date"].to_date
        prefs[date] = {
            "minutes" => i["minute"],
            "file_ids" => i["file_ids"].uniq,
        }
      end
      prefs
    end

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

  def save_results
    return if in_results.blank?

    in_results.each do |id, result|
      next if result["start_at_date"].blank? || result["start_at_hour"].blank? || result["start_at_minute"].blank?
      next if result["end_at_date"].blank? || result["end_at_hour"].blank? || result["end_at_minute"].blank?
      #next if result["break_time_minute"].blank?

      s_at = Time.zone.parse("#{result["start_at_date"]} #{result["start_at_hour"]}:#{result["start_at_minute"]}")
      e_at = Time.zone.parse("#{result["end_at_date"]} #{result["end_at_hour"]}:#{result["end_at_minute"]}")

      file = self.class.find(id)

      item = Gws::Affair::OvertimeResult.new
      item.date = file.date
      item.start_at = s_at
      item.end_at = e_at
      item.break_time_minute = result["break_time_minute"]

      file.result = item
      file.save
    end

    true
  end
end
