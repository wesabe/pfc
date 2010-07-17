module UploadsHelper
  def txaction_date_range(upload)
    min = upload.txactions.minimum(:date_posted)
    max = upload.txactions.maximum(:date_posted)
    return 'n/a' if min.nil? || max.nil?

    result = very_short_friendly_date(min)
    result << '..' << very_short_friendly_date(max) unless min.to_date == max.to_date
    return result
  end

  # Renders the Javascript required to redirect the browser to FI#new including
  # the FI name the user typed in.
  def new_bank_js_link(input_element_id)
    %Q{
      var bank_name = $('##{input_element_id}').val();
      if(bank_name != ''){
        window.location.href = '#{new_financial_inst_url}?name=' + encodeURIComponent(bank_name);
      } else {
        alert('Try typing in the first few letters of your bank or credit card. If you don\\'t see it, then click this link to add it.');
      }
    }.gsub(/[\s]+/m, " ")
  end

  def login_field_for(field)
    content_tag(:label, "#{field[:label]} #{content_tag(:span, "", :class => "error_message", :style => "display:none")}", :for => field[:key], :class => 'field-title') +
    case field[:type]
    when "password"
      password_field_tag(field[:key], "", :class => "medium_text_field cred_field")
    when "state"
      %{<select class="cred_field state_select" id="#{field[:key]}" name="#{field[:key]}">\n} +
        %{<option value="">-- choose state --</option>} +
        options_for_select(Constants::STATES) + %{\n</select>}
    else # "text"
      text_field_tag(field[:key], "", :class => "medium_text_field cred_field initial-focus", :autocomplete => "off")
    end
  end

  def help_text_for(fi)
    case text = fi.help_text(:ssu)
    when /<[a-z]+(\s[^>]*)?>/
      text
    else
      auto_link text.
        sub(/^(.*?(?:[\.\!\?](?=[ <])|[\.\!\?]$|$))/) { "<strong>#{$1}</strong>" }.
        gsub("\n", "<br/>\n"),
      :all, :target => '_blank'
    end
  end
end
