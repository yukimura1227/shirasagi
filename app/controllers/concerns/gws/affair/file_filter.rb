module Gws::Affair::FileFilter
  extend ActiveSupport::Concern

  private

  def set_search_params
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.state = params[:state] if params[:state]
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def set_items
    set_search_params
    @items = @model.site(@cur_site).search(@s)
  end

  public

  def index
    set_items
  end
end
