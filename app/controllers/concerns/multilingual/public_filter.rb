module Multilingual::PublicFilter
  extend ActiveSupport::Concern

  private
    def multilingual_path?
      filters.include?(:multilingual)
    end

    def set_request_path_with_multilingual
      I18n.locale = I18n.default_locale
      Multilingual::Initializer.lang = nil
      langs = Multilingual::Node::Lang.site(@cur_site).and_public.pluck(:filename)

      return if langs.blank?
      return if @cur_path !~ /^\/(#{langs.join("|")})\//
      Multilingual::Initializer.lang = @cur_path.scan(/^\/(#{langs.join("|")})\//).flatten.first
      I18n.locale = Multilingual::Initializer.lang
      Multilingual::Initializer.preview = preview_path?
      @cur_path.sub!(/^\/(#{langs.join("|")})\//, "/")

      filters << :multilingual
    end

    def render_multilingual
      return if response.content_type != "text/html"
      body = response.body

      # links
      location = Multilingual::Initializer.lang
      body.gsub!(/(href|action)="(?!:\w\w:).*?"/) do |m|
        url = m.match(/="(.*?)"/)[1]
        if url =~ /^\/(#{location}|fs|assets|assets-dev)\//
          m
        elsif url =~ /^\/(?!\/).*?(\/|\.html)$/
          m.sub(/="/, "=\"/#{location}")
        elsif url == "/"
          m.sub(/="/, "=\"/#{location}")
        else
          m
        end
      end

      render_multilingual_url(body)
    end

    def render_multilingual_url(body = response.body)
      return if response.content_type != "text/html"

      langs = {}
      body.gsub!(/(href|action)=":(\w\w):(.+?)"/) do |m|
        attr = $1
        lang_code = $2
        url = $3

        langs[lang_code] ||= begin
          Multilingual::Node::Lang.site(@cur_site).and_public.where(filename: lang_code, depth: 1).first
        end
        if langs[lang_code]
          url = url[1..-1] if url.start_with?("/")
          url = "#{langs[lang_code].url}#{url}"
        end

        "#{attr}=\"#{url}\""
      end

      response.body = body
    end
end
