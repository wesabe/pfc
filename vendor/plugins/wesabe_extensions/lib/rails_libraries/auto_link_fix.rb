module ActionView
  module Helpers
    module TextHelper

      def collapse(text, max_length, number_of_characters_at_end = 10, connector_text = '...')
        if text.size > max_length
          text[0, max_length - number_of_characters_at_end - connector_text.size].to_s << '...' << text[-number_of_characters_at_end, number_of_characters_at_end]
        else
          text
        end
      end

      def auto_link_with_truncate(text, types = :all, options = {})
        auto_link_without_truncate(text, types, options) do |text|
          collapse(text, 50)
        end
      end
      alias :auto_link_without_truncate :auto_link
      alias :auto_link :auto_link_with_truncate

      def simple_format_with_strip(text)
        simple_format_without_strip(text.to_s.strip)
      end
      alias :simple_format_without_strip :simple_format
      alias :simple_format :simple_format_with_strip


      private
      remove_const(:AUTO_LINK_RE) if const_defined?(:AUTO_LINK_RE)
      AUTO_LINK_RE = %r{
                      (                          # leading text
                        <\w+.*?>|                # leading HTML tag, or
                        [^=!:'"/]|               # leading punctuation, or
                        ^                        # beginning of line
                      )
                      (
                        (?:https?://)|           # protocol spec, or
                        (?:www\.)                # www.*
                      )
                      (
                        [-\w]+                   # subdomain or domain
                        (?:\.[-\w]+)*            # remaining subdomains or domain
                        (?::\d+)?                # port
                        (?:/(?:[~\w\+@%=-]|(?:[,.;:'][^\s$]))*)* # path
                        (?:\?[\w\+@%&=.;-]+)?     # query string
                        (?:\#[\w\-]*)?           # trailing anchor
                      )
                      ([[:punct:]]|<|$|)       # trailing text
                     }x
    end
  end
end