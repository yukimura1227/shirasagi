class Gws::Affair::Overtime::ResultsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::AjaxFilter

  model Gws::Affair::OvertimeFile

  def set_item
    @item = Gws::Affair::OvertimeFile.site(@cur_site).find(params[:id])

    @user = @item.user
    @site = @item.site
    @date = @item.date

    @items = @files = Gws::Affair::OvertimeFile.site(@site).user(@user).where(
        workflow_state: "approve",
        date: @date
    ).reorder(start_at: 1)
  end

  def update
    @item.attributes = get_params
    render_update @item.save_results, location: params[:ref]
  end
end
