class Gws::Affair::Overtime::Apis::FilesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::OvertimeFile

  def week_in
    @user = Gws::User.find(params[:uid])
    @leave_file = Gws::Affair::LeaveFile.find(params[:id]) rescue nil

    file_ids = Gws::Affair::LeaveFile.site(@cur_site).where(workflow_state: "approve").
      pluck(:week_in_compensatory_file_id).compact
    file_ids -= [@leave_file.week_in_compensatory_file_id] if @leave_file

    @items = @model.site(@cur_site).user(@user).where(
      workflow_state: "approve",
      week_in_compensatory_minute: { "$gt" =>  0 },
      id: { "$nin" => file_ids }
    )
  end
  
  def week_out
    @user = Gws::User.find(params[:uid])
    @leave_file = Gws::Affair::LeaveFile.find(params[:id]) rescue nil

    file_ids = Gws::Affair::LeaveFile.site(@cur_site).where(workflow_state: "approve").
      pluck(:week_out_compensatory_file_id).compact
    file_ids -= [@leave_file.week_out_compensatory_file_id] if @leave_file

    @items = @model.site(@cur_site).user(@user).where(
      workflow_state: "approve",
      week_out_compensatory_minute: { "$gt" =>  0 },
      id: { "$nin" => file_ids }
    )
  end
end
