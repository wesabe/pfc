module ActionView
  module Helpers
    module DateHelper
      def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        distance_in_minutes = (((to_time - from_time).abs)/60).round
        distance_in_seconds = ((to_time - from_time).abs).round

        case distance_in_minutes
          when 0..1
            return (distance_in_minutes==0) ? 'less than a minute' : '1 minute' unless include_seconds
            case distance_in_seconds
              when 0..5   then 'less than 5 seconds'
              when 6..10  then 'less than 10 seconds'
              when 11..20 then 'less than 20 seconds'
              when 21..40 then 'half a minute'
              when 41..59 then 'less than a minute'
              else             '1 minute'
            end
                                
          when 2..45      then "#{distance_in_minutes} minutes"
          when 46..90     then 'about 1 hour'
          when 90..1440   then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
          when 1441..2880 then '1 day'
          when 2881..86400 then "#{(distance_in_minutes / 1440).round} days"
          when 86401..525600 then "#{(distance_in_minutes / 43200).round} months" 
          else
            years = (distance_in_minutes / 525600).round
            months = (distance_in_minutes / 43200).round - years * 12
            # needed because of the inherent inaccuracy of rails time (1.year.ago != 525600 minutes)
            if months == 12
              years += 1
              months = 0
            end
            "#{years} year#{'s' if years > 1}" + (months > 0 ? ", #{months} month#{'s' if months > 1}" : '')    
        end
      end
    end
  end
end