class Gws::Affair::CapitalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::Capital

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t('modules.gws/affair/capital'), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
