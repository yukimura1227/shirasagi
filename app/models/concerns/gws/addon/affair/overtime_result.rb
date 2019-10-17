module Gws::Addon::Affair::OvertimeResult
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_results
    permit_params in_results: {}

    embeds_one :result, class_name: "Gws::Affair::OvertimeResult"
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
