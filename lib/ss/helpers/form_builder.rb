module SS::Helpers
  class FormBuilder < ActionView::Helpers::FormBuilder
    def hidden_field(method, options = {})
      return super if method !~ /\[/

      object_method = "#{@object_name}[" + method.sub("[", "][")
      value = options[:value] || array_value(method)
      options.delete(:value)

      if !value.is_a?(Array) || value.empty?
        return @template.hidden_field_tag(object_method, value, options)
      end

      tags = value.map do |v|
        options[:id] ||= object_method.gsub(/\W+/, "_") + v.to_s
        @template.hidden_field_tag(object_method, v, options)
      end
      tags.join.html_safe
    end

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      return super if method !~ /\[/

      object_method = "#{@object_name}[" + method.sub("[", "][")
      if method.end_with?('[]')
        checked = array_value(method).include?(checked_value)
        options[:id] ||= object_method.gsub(/\W+/, "_") + checked_value.to_s
      else
        checked = array_value(method).present?
      end

      @template.check_box_tag(object_method, checked_value, checked, options)
    end

    def ss_field_set(method, options = {}, &block)
      model = @template.assigns["model"]

      method = method.to_sym
      tt = normalize_tooltip(options.delete(:tt), model, method)
      label_text = options.fetch(:label, model.t(method))
      options.delete(:label)

      @template.content_tag(:div, class: "col12 mb-3") do
        if label_text.present?
          @template.output_buffer << label(method) do
            @template.output_buffer << label_text
            if tt
              @template.output_buffer << tt
            end
          end
        end
        if block_given?
          @template.output_buffer << @template.capture { yield }
        else
          type = options.delete(:type)
          # value = options[:value]
          case guess_type(type, model, method, options.key?(:value) ? [ options[:value] ] : [])
          when :text
            @template.output_buffer << text_field(method, options)
          when :password
            @template.output_buffer << password_field(method, options)
          when :email
            @template.output_buffer << email_field(method, options)
          when :url
            @template.output_buffer << url_field(method, options)
          when :tel
            @template.output_buffer << telephone_field(method, options)
          when :hidden
            @template.output_buffer << hidden_field(method, options)
          when :number
            @template.output_buffer << number_field(method, options)
          when :file
            @template.output_buffer << file_field(method, options)
          when :text_area
            @template.output_buffer << text_area(method, options)
          when :date
            options[:class] = %w(date js-date)
            value ||= begin
              object = @template.instance_variable_get(:"@#{object_name}")
              object.send(method)
            end
            options[:value] = value ? I18n.l(value.to_date, format: :picker) : nil
            @template.output_buffer << text_field(method, options)
          when :datetime
            options[:class] = %w(datetime js-datetime)
            value ||= begin
              object = @template.instance_variable_get(:"@#{object_name}")
              object.send(method)
            end
            options[:value] = value ? I18n.l(value, format: :picker) : nil
            @template.output_buffer << text_field(method, options)
          else
            raise "unknown type: #{type}"
          end
        end
      end
    end

    def ss_select_set(method, options = {}, html_options = {})
      model = @template.assigns["model"]

      method = method.to_sym
      tt = normalize_tooltip(options.delete(:tt), model, method)

      @template.content_tag(:div, class: "col12 mb-3") do
        @template.output_buffer << label(method) do
          @template.output_buffer << model.t(method)
          if tt
            @template.output_buffer << tt
          end
        end

        choices = options.delete(:choices)
        choices ||= begin
          object = @template.instance_variable_get(:"@#{object_name}")
          object.send("#{method}_options")
        end
        @template.output_buffer << select(method, choices, options, html_options)
      end
    end

    private

    def array_value(method)
      item = @template.instance_variable_get(:"@#{@object_name}")
      normalized = method.sub(/\[\]$/, "").gsub(/\[(\D.*?)\]/, '["\\1"]')

      if method.end_with?('[]')
        item.send(normalized) || []
      else
        item.send(normalized)
      end
    end

    def normalize_tooltip(tooltip, model, method)
      return unless tooltip
      return tooltip if !tooltip.is_a?(TrueClass)

      model.tt(method)
    end

    # rubocop:disable Style/ZeroLengthPredicate
    def guess_type(type, model, method, optional_value)
      return type if type.present? && type != :auto

      klass = optional_value.length > 0 ? optional_value.first.class : model.fields[method.to_s].type
      if klass == Integer
        :number
      elsif klass == DateTime
        :datetime
      else
        :text
      end
    end
    # rubocop:enable Style/ZeroLengthPredicate
  end
end
