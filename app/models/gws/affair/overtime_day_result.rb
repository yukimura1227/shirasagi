class Gws::Affair::OvertimeDayResult
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site

  belongs_to :file, class_name: "Gws::Affair::OvertimeFile"
  field :date, type: DateTime
  field :start_at, type: DateTime
  field :end_at, type: DateTime

  belongs_to :capital, class_name: "Gws::Affair::Capital"
  field :is_holiday, type: Boolean
  field :overtime_minute, type: Integer
  field :duty_day_time_minute, type: Integer
  field :duty_night_time_minute, type: Integer
  field :leave_day_time_minute, type: Integer
  field :leave_night_time_minute, type: Integer
  field :week_in_compensatory_minute, type: Integer
  field :week_out_compensatory_minute, type: Integer
  field :break_time_minute, type: Integer

  validates :file_id, presence: true
  validates :date, presence: true, uniqueness: { scope: [:site_id, :user_id, :file_id] }

  validates :capital_id, presence: true
  validates :is_holiday, presence: true
  validates :overtime_minute, presence: true
  validates :duty_day_time_minute, presence: true
  validates :duty_night_time_minute, presence: true
  validates :leave_day_time_minute, presence: true
  validates :leave_night_time_minute, presence: true
  validates :week_in_compensatory_minute, presence: true
  validates :week_out_compensatory_minute, presence: true
  validates :break_time_minute, presence: true

  def day_time_minute
    is_holiday ? leave_day_time_minute : duty_day_time_minute
  end

  def night_time_minute
    is_holiday ? leave_night_time_minute : duty_night_time_minute
  end

  class << self
    def aggregate_by_user
      match_pipeline = self.criteria.selector
      group_pipeline = {
        _id: {
          user_id: "$user_id",
          date: "$date"
        },
        duty_day_time_minute: { "$sum" => "$duty_day_time_minute" },
        duty_night_time_minute: { "$sum" => "$duty_night_time_minute" },
        leave_day_time_minute: { "$sum" => "$leave_day_time_minute" },
        leave_night_time_minute: { "$sum" => "$leave_night_time_minute" },
        week_out_compensatory_minute: { "$sum" => "$week_out_compensatory_minute" },
      }
      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => { user_id: -1, date: -1 } }

      prefs = {}
      threshold = SS.config.gws.affair.dig("overtime", "aggregate", "threshold_hour") * 60

      aggregation = self.collection.aggregate(pipes)
      aggregation.each do |i|
        user_id = i["_id"]["user_id"]

        prefs[user_id] ||= {}
        prefs[user_id]["threshold"] ||=Gws::Affair::Subtractor.new(threshold)

        d_d_m = i["duty_day_time_minute"]
        d_n_m = i["duty_night_time_minute"]
        l_d_m = i["leave_day_time_minute"]
        l_n_m = i["leave_night_time_minute"]
        w_c_m = i["week_out_compensatory_minute"]

        under_minutes, over_minutes = prefs[user_id]["threshold"].subtract(d_d_m, d_n_m, l_d_m, l_n_m, w_c_m)

        prefs[user_id]["under_threshold"] ||= {
          "duty_day_time_minute" => 0,
          "duty_night_time_minute" => 0,
          "leave_day_time_minute" => 0,
          "leave_night_time_minute" => 0,
          "week_out_compensatory_minute" => 0
        }
        prefs[user_id]["under_threshold"]["duty_day_time_minute"] += under_minutes[0]
        prefs[user_id]["under_threshold"]["duty_night_time_minute"] += under_minutes[1]
        prefs[user_id]["under_threshold"]["leave_day_time_minute"] += under_minutes[2]
        prefs[user_id]["under_threshold"]["leave_night_time_minute"] += under_minutes[3]
        prefs[user_id]["under_threshold"]["week_out_compensatory_minute"] += under_minutes[4]

        prefs[user_id]["over_threshold"] ||= {
          "duty_day_time_minute" => 0,
          "duty_night_time_minute" => 0,
          "leave_day_time_minute" => 0,
          "leave_night_time_minute" => 0,
          "week_out_compensatory_minute" => 0
        }
        prefs[user_id]["over_threshold"]["duty_day_time_minute"] += over_minutes[0]
        prefs[user_id]["over_threshold"]["duty_night_time_minute"] += over_minutes[1]
        prefs[user_id]["over_threshold"]["leave_day_time_minute"] += over_minutes[2]
        prefs[user_id]["over_threshold"]["leave_night_time_minute"] += over_minutes[3]
        prefs[user_id]["over_threshold"]["week_out_compensatory_minute"] += over_minutes[4]
      end
      prefs
    end
  end
end
