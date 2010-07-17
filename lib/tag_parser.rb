require 'simple_calc'

class TagParser
  # parse a string of tag names into an array of tag names
  def self.parse(list)
    return [] unless list

    tag_names = []
    list.strip!
    return tag_names unless list

    # if list contains commas and no quotes, use the commas as separators
    if list.include?(',') && !list.include?('"')
      tag_names = list.split(/\s*,\s*/)
    else
      # accomodates single- and double-quoted tags, commas, and splits
      # "one:-10 two \"three\", \"four, five\":+10, 'six seven' \"eight's nine:100\", ten, eleven:1/3 twelve:15.5% \"  \""
      tag_names =  list.scan(/
                              (?:
                                (
                                  (["'])
                                  \s*
                                  (\S.*?)
                                  \s*
                                  \2
                                  (?::[^\s,]+)?
                                )
                              ) |
                              (?:
                                \b
                                ([^\s,]+)
                                (?:[\s,]|$)
                              )
                              /x).collect {|m| (m[0]||m[3]).gsub(/^(['"])(.*?)\1(:.*|$)/, '\2\3')}
    end

    return tag_names.uniq.reject {|t| t.blank?}
  end

  # given a "tag:<split>" string and an optional amount, return the calculated split amount as a float
  def self.calculate_split(tag, amount = 0)
    (name, split) = tag.split(":")
    return nil unless split

    if split.match(/^[.\d]+$/)
      split = split.to_f.abs
    elsif m = split.match(/^(\d+)\/([.\d]+)$/)
      split = (m[1].to_f / m[2].to_f).abs * (amount.abs || 1)
    elsif m = split.match(/^([.\d]+)%$/)
      split = (m[1].to_f/ 100).abs * (amount.abs || 1)
    elsif m = split.match(/^=?(.*)$/)
      begin
        parser = SimpleCalc.new
        split = parser.parse(m[1]).to_f.abs
      rescue
        split = 0
      end
    else
      split = 0
    end

    split_sign = amount >= 0 ? 1 : -1

    return split * split_sign
  end
end
