namespace :affair do
  task create_sample: :environment do
    puts "Please input site_id: site=[site_id]" or exit if ENV['site'].blank?
    puts "Please input user_id name: user=[user_id]" or exit if ENV['user'].blank?

    @site = Gws::Group.find(ENV['site'])
    @user = Gws::User.find(ENV['user'])

    current = Time.zone.now
    end_of_month = current.end_of_month.day

    @start_day = (ENV['start_day'] || 1).to_i
    @end_day = (ENV['end_day'] || end_of_month).to_i

    @capital_ids = Gws::Affair::Capital.site(@site).allow(:read, @user, site: @site).pluck(:id)

    duty_hour = @user.effective_duty_hour(@site)
    duty_hour.cur_user = @user

    duty_start_hour = duty_hour.affair_start(current).hour
    duty_end_hour = duty_hour.affair_end(current).hour

    overtime_total = 0

    (@start_day..@end_day).each do |day|
      date = current.change(day: day, hour: 0, min: 0, sec: 0)

      if duty_hour.leave_day?(date)
        overtime_hour = (duty_end_hour - duty_start_hour) + rand(1..4)
        overtime_total += overtime_hour

        item = Gws::Affair::OvertimeFile.new
        item.cur_site = @site
        item.cur_user = @user
        item.name = "[休祝日] 参院選事務 #{date.strftime("%Y/%m/%d")}"
        item.overtime_name = "参院選事務"
        item.date = date
        item.start_at = date.change(hour: duty_start_hour, min: 0, sec: 0)
        item.end_at = item.start_at.advance(hours: overtime_hour)
        item.capital_id = @capital_ids.sample
        item.remark = "備考です。"

        # workflow
        item.state = "approve"
        item.workflow_user_id = @user.id
        item.workflow_state = "approve"
        item.workflow_current_circulation_level = 0
        item.workflow_approvers = [
          { "level" =>1, "user_id" =>1, "editable" => "", "state" => "approve", "comment" => "承認しました。", "file_ids" => nil }
        ]
        item.workflow_required_counts = [false]
        item.approved = Time.zone.now

        # groups
        item.readable_group_ids = [@user.gws_main_group(@site)]
        item.group_ids = [@user.gws_main_group(@site)]
        item.user_ids = [@user.id]
        item.save!

        # result
        item.in_results = {
          item.id => {
            "start_at_date" => item.start_at.strftime("%Y/%m/%d"),
            "start_at_hour" => item.start_at.hour,
            "start_at_minute" => item.start_at.minute,
            "end_at_date" => item.end_at.strftime("%Y/%m/%d"),
            "end_at_hour" => item.end_at.hour,
            "end_at_minute" => item.end_at.minute,
            "break_time_minute" => 45
          }
        }
        item.save_results

        puts "leave_day #{date.strftime("%Y/%m/%d")} 時間外：#{overtime_hour}"
      else
        overtime_hour = rand(1..4)
        overtime_total += overtime_hour

        item = Gws::Affair::OvertimeFile.new
        item.cur_site = @site
        item.cur_user = @user
        item.name = "[勤務日] 参院選事務 #{date.strftime("%Y/%m/%d")}"
        item.overtime_name = "参院選事務"
        item.date = date
        item.start_at = date.change(hour: duty_end_hour, min: 0, sec: 0)
        item.end_at = item.start_at.advance(hours: overtime_hour)
        item.capital_id = @capital_ids.sample
        item.remark = "備考です。"

        item.readable_group_ids = [@user.gws_main_group(@site)]
        item.group_ids = [@user.gws_main_group(@site)]
        item.user_ids = [@user.id]

        # workflow
        item.state = "approve"
        item.workflow_user_id = @user.id
        item.workflow_state = "approve"
        item.workflow_current_circulation_level = 0
        item.workflow_approvers = [
          { "level" =>1, "user_id" =>1, "editable" => "", "state" => "approve", "comment" => "承認しました。", "file_ids" => nil }
        ]
        item.workflow_required_counts = [false]
        item.approved = Time.zone.now

        # groups
        item.readable_group_ids = [@user.gws_main_group(@site)]
        item.group_ids = [@user.gws_main_group(@site)]
        item.user_ids = [@user.id]
        item.save!

        # result
        item.in_results = {
          item.id => {
            "start_at_date" => item.start_at.strftime("%Y/%m/%d"),
            "start_at_hour" => item.start_at.hour,
            "start_at_minute" => item.start_at.minute,
            "end_at_date" => item.end_at.strftime("%Y/%m/%d"),
            "end_at_hour" => item.end_at.hour,
            "end_at_minute" => item.end_at.minute,
            "break_time_minute" => 0
          }
        }
        item.save_results

        puts "duty_day  #{date.strftime("%Y/%m/%d")} 時間外：#{overtime_hour}"

      end
    end

    puts "計 #{overtime_total}h"
  end
end
