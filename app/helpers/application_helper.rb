module ApplicationHelper
  def stylesheet(*stylesheets)
    content_for(:header) do
      stylesheet_link_tag(stylesheets.join(","))
    end
  end

  def javascript(*javascripts)
    @included_js ||= []
    javascripts.reject! do |j|
      if @included_js.include?(j)
        true
      else
        @included_js << j
        false
      end
    end

    content_for(:footer) do
      javascript_include_tag(javascripts)
    end if javascripts.any?
  end

  # return the referer as a hash {:controller => c, :action => a, ...}
  def internal_referer
    uri = URI.parse(request.env["HTTP_REFERER"])
    return nil unless %w(http https).include?(uri.scheme)
    # make sure internal referers come from wesabe in production
    return nil if Rails.env.production? && uri.host !~ /wesabe.com/
    # check to see if there is a route with the path we can redirect to
    path = Rails.application.routes.recognize_path(uri.path, :method => :get)
    return nil if %w(xml xls csv qif ofx ofx2).include?(path[:format])
    return path
  rescue ActionController::RoutingError, URI::InvalidURIError
  end
  alias :internal_referrer :internal_referer # for the pedantic

  #
  # HTML helpers
  #

  def set_page_title(*title_elements)
    title_elements.unshift("Wesabe") unless title_elements.first.starts_with?("Wesabe")
    @_page_title = title_elements.join(": ")
  end

  def error_messages_for(object_name, options = {})
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}")
    if object && !object.errors.empty?
      content_tag("div",
        content_tag(
          options[:header_tag] || "h2",
          "We couldn't #{object.new_record? ? "create" : "save your changes to"} this #{object_name.to_s.gsub('_', ' ')}."
          # "There were #{pluralize(object.errors.count, "error")} while trying to save this #{object_name.to_s.gsub("_", " ")}"
        ) +
        content_tag("p", "There were problems with the following fields:") +
        content_tag("ul", object.errors.full_messages.collect { |msg| content_tag("li", msg) }),
        "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
      )
    else
      ""
    end
  end

  def flash_error(error_for = nil)
    if flash[:error]
      return if error_for && flash[:error_for] != error_for
       "<div class=\"error-message\">#{flash[:error]}</div>"
    end
  end

  # NOTE: users of page_title should handle escaping with <title><%=h page_title %></title>
  def page_title
    @_page_title || 'Wesabe: Your money. Your community.'
  end

  # link showing a url, not too long, and omitting protocol info
  def link_to_url(url)
    link_to truncate(sanitize(url).sub(%r{^https?://}, ''), :length => 30), sanitize(url) unless url.blank?
  end

  def help_url(path=nil)
    case path
    when nil
      "/help"
    when Array
      "/help/#{path.join('/')}"
    when String
      "/help/#{path}"
    end
  end

  #
  # Utility methods
  #

  # return friendly date format:
  # Sunday, May 14th [+ year if not current year]
  def friendly_date(date)
    if date
      date.strftime("%A, %B ") + date.day.ordinalize + (date.year != Time.now.year ? ", #{date.year}" : '')
    else
      ''
    end
  end

  # return short friendly date format:
  # May 14th [+ year if not current year]
  def short_friendly_date(date)
    if date
      date.strftime("%B ") + date.day.ordinalize + (date.year != Time.now.year ? ", #{date.year}" : '')
    else
      ''
    end
  end

  # return short friendly date format:
  # Oct. 14 [+ year if not current year]
  def very_short_friendly_date(date)
    if date
      date.strftime("%b %e") + (date.year != Time.now.year ? ", #{date.year}" : '')
    else
      ''
    end
  end

  # return the month name for the given month
  def month_name(month)
    Date::MONTHNAMES[month]
  end

  def userbar_profile_link(user)
    link_text = user.name
    if user.anonymous?
      link_text += ' <span style="font-size:90%">(set your screen name)</span>'
    end
    link_to(link_text, edit_profile_url, :title => 'Edit your profile, manage your account, and more.')
  end

  def user_profile_link(user, options={})
    include_photo = options.has_key?(:include_photo) ? options[:include_photo] : true
    link_text = options[:link_text]

    name = include_photo ? image_tag(user.image_path(:thumb) || user.image_path(:profile), :alt => link_text || user.display_name) : ''
    unless link_text && link_text.empty?
      display_name = link_text || h(user.display_name)
      display_name.gsub!(/(\S{12})/, '\1<span class="name-break"> </span>')
      name << '<br />' if include_photo
      name << display_name
    end

    if options[:show_badge]
      name << "<br/>" << image_tag("wesabe-tiny.gif", :alt => "Works at Wesabe", :title => "Works at Wesabe", :class => "badge")
    end

    link_to(name, user_path, {:class => 'author', :alt => link_text || h(user.display_name)})
  end

  # return true if the result of a file upload is really a file
  # from http://cleanair.highgroove.com/articles/2006/10/03/mini-file-uploads
  def file_provided?(uploaded_file)
    uploaded_file.respond_to?(:read)
  end

  def logo
    link_to("Wesabe: Your money. Your community.", root_url, :id => 'logo')
  end
end
