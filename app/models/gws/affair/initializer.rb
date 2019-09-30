module Gws::Affair
  class Initializer
    Gws::Role.permission :use_gws_attendance_time_cards, module_name: 'gws/attendance'
    Gws::Role.permission :edit_gws_attendance_time_cards, module_name: 'gws/attendance'
    Gws::Role.permission :manage_private_gws_attendance_time_cards, module_name: 'gws/attendance'
    Gws::Role.permission :manage_all_gws_attendance_time_cards, module_name: 'gws/attendance'

    Gws.module_usable :attendance do |site, user|
      Gws::Attendance.allowed?(:use, user, site: site)
    end

    Gws::Role.permission :read_other_gws_affair_capitals, module_name: 'gws/affair'
    Gws::Role.permission :read_private_gws_affair_capitals, module_name: 'gws/affair'
    Gws::Role.permission :edit_other_gws_affair_capitals, module_name: 'gws/affair'
    Gws::Role.permission :edit_private_gws_affair_capitals, module_name: 'gws/affair'
    Gws::Role.permission :delete_other_gws_affair_capitals, module_name: 'gws/affair'
    Gws::Role.permission :delete_private_gws_affair_capitals, module_name: 'gws/affair'

    Gws::Role.permission :read_other_gws_affair_dutyhours, module_name: 'gws/affair'
    Gws::Role.permission :read_private_gws_affair_dutyhours, module_name: 'gws/affair'
    Gws::Role.permission :edit_other_gws_affair_dutyhours, module_name: 'gws/affair'
    Gws::Role.permission :edit_private_gws_affair_dutyhours, module_name: 'gws/affair'
    Gws::Role.permission :delete_other_gws_affair_dutyhours, module_name: 'gws/affair'
    Gws::Role.permission :delete_private_gws_affair_dutyhours, module_name: 'gws/affair'

    Gws::Role.permission :read_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :read_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_other_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_private_gws_affair_overtime_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_other_gws_affair_overtime_files, module_name: 'gws/affair'

    Gws::Role.permission :read_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :read_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :edit_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :delete_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :approve_other_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_private_gws_affair_leave_files, module_name: 'gws/affair'
    Gws::Role.permission :reroute_other_gws_affair_leave_files, module_name: 'gws/affair'
  end
end
