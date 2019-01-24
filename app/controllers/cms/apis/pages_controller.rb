class Cms::Apis::PagesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  before_action :set_selected_node

  private

  def set_selected_node
    node_id = params.dig(:s, :node)
    if node_id.present? && node_id != "all"
      @selected_node = Cms::Node.site(@cur_site).where(id: node_id.to_s).first
      @selected_node = @selected_node.becomes_with_route if @selected_node
    end
  end

  public

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site)
    if @selected_node.present?
      @items = @items.where(filename: /^#{::Regexp.escape(@selected_node.filename)}\//)
    end
    @items = @items.search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end

  def routes
    @items = @model.routes
  end
end
