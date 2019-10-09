class Gws::Affair::DutyHoursController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::DutyHour

  navi_view "gws/affair/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    @item ||= begin
      if params[:id] == "default"
        Gws::Affair::DefaultDutyHour.wrap(@cur_site)
      else
        item = @model.find(params[:id])
        item.attributes = fix_params
        item
      end
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end
end
