xml.instruct!
xml.dasherize!
set_filename_for_export "targets", :xml
xml.targets(:type => "array") do
  unless @targets.nil? || @targets.empty?
    for target in @targets
      xml.target do
        xml.tag do
          xml.name(target.tag_name)
        end
        xml.monthly_limit(number_to_currency(target.amount_per_month, :unit => '', :delimiter => ''), :type => "float")
        xml.amount_remaining(number_to_currency(target.amount_remaining, :unit => '', :delimiter => ''), :type => "float")
        xml.amount_spent(number_to_currency(target.amount_spent, :unit => '', :delimiter => ''), :type => "float")
      end
    end
  end
end
