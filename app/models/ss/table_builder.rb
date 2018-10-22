class SS::TableBuilder

  class Column
    attr_accessor :th, :td

    def render_th
      @th.call
    end

    def render_td(item)
      @td.call(item)
    end
  end

  def initialize(bind)
    @bind = bind
    @columns = []
  end

  attr_reader :columns

  def build(&block)
    yield(self)
    self
  end

  def column(*args, &block)
    @column = Column.new
    @column_options = args.extract_options!

    yield

    raise "th is required" if @column.th.blank?
    raise "td is required" if @column.td.blank?

    @columns << @column
    @column = nil
  end

  def tap_menu(*args, &block)
    column do
      th ""
      td do |item|
        capture do
          output_buffer << "<div class=\"dropdown\">".html_safe
          output_buffer << @bind.receiver.button_tag(
            name: nil, type: "button", class: "btn btn-no-outline bmd-btn-icon dropdown-toggle",
            data: { toggle: "dropdown" }, aria: { haspopup: true, expanded: false }) do
            content_tag(:i, "more_vert", class: "material-icons")
          end
          output_buffer << "<div class=\"dropdown-menu dropdown-menu-left\">".html_safe
          if block_given?
            yield item
          else
            default_tap_menu(item, args.presence || %i[show edit delete])
          end
          output_buffer << "</div>".html_safe
          output_buffer << "</div>".html_safe
        end
      end
    end
  end

  def column_checkbox
    column(class: "check") do
      th "<input type=\"checkbox\" />".html_safe
      td do |item|
        "<div class=\"checkbox\"><input type=\"checkbox\" name=\"ids[]\" value=\"#{item.id}\" /></div>".html_safe
      end
    end
  end

  def column_updated
    column(class: "datetime") do
      th I18n.t("cms.options.sort.updated_1")
      td do |item|
        if item.respond_to?(:updated)
          item.updated.strftime("%Y/%m/%d %H:%M")
        end
      end
    end
  end

  def th(*args, &block)
    options = args.extract_options!
    options = options.reverse_merge(@column_options)
    if block_given?
      @column.th = proc { capture { content_tag("th", options, &block) } }
    else
      content = args.first
      @column.th = proc { content_tag("th", content, options) }
    end
  end

  def td(*args, &block)
    raise "block is required" if !block_given?
    options = args.extract_options!
    options = options.reverse_merge(@column_options)
    @column.td = proc { |item| capture { content_tag("td", options) { yield item } } }
  end

  def method_missing(name, *args, &block)
    if @bind.receiver.respond_to?(name)
      @bind.receiver.send(name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_private)
    @bind.receiver.respond_to?(symbol, include_private) || super
  end

  private

  def default_tap_menu(item, scopes)
    user = @bind.eval("@cur_user")
    site = @bind.eval("@cur_site")
    if scopes.include?(:show) && item.allowed?(:read, user, site: site)
      output_buffer << link_to(t('ss.links.show'), { action: :show, id: item }, { class: "dropdown-item" })
    end
    if scopes.include?(:edit) && item.allowed?(:edit, user, site: site)
      output_buffer << link_to(t('ss.links.edit'), { action: :edit, id: item }, { class: "dropdown-item" })
    end
    if scopes.include?(:delete) && item.allowed?(:delete, user, site: site)
      output_buffer << link_to(t('ss.links.delete'), { action: :delete, id: item }, { class: "dropdown-item" })
    end

    if scopes.include?(:public) && item.public?
      output_buffer << link_to(I18n.t("ss.links.view_site"), item.full_url, class: "dropdown-item", target: "_blank")
    end

    if scopes.include?(:preview)
      if site.mobile_enabled?
        output_buffer << link_to(I18n.t("ss.links.pc_preview"), cms_preview_path(path: item.preview_path),
                                 target: "_blank", class: "dropdown-item")
        output_buffer << link_to(I18n.t("ss.links.mobile_preview"), cms_mobile_preview_path(path: item.preview_path),
                                 target: "_blank", class: "dropdown-item")
      else
        output_buffer << link_to(t("ss.links.preview"), cms_preview_path(path: item.preview_path),
                                 target: "_blank", class: "dropdown-item")
      end
    end

    if scopes.include?(:image)
      if item.try(:image)
        image_tag = image_tag(item.image.thumb_url)
        url = item.image.url
      elsif item.try(:image?)
        image_tag = image_tag("#{item.thumb_url}?_=#{item.updated.to_i}", alt: '')
        url = item.url
      end
      if image_tag
        output_buffer << link_to(image_tag, url, { class: "dropdown-item thumb", target: "_blank" })
      end
    end
  end
end
