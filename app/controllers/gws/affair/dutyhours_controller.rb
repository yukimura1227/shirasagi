class Gws::Affair::DutyhoursController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::Dutyhour

  navi_view "gws/affair/main/navi"

  private

  #def set_crumbs
  #  @crumbs << [@cur_site.menu_workflow_label || t('modules.gws/workflow'), gws_workflow_setting_path]
  #  @crumbs << [@model.model_name.human, action: :index]
  #end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
