# constants that are (or potentially can be) used in more than
# one place in the application
module Constants
  module Status
    def self.string_for(code)
      constants.each do |const|
        return const.capitalize if const_get(const) == code
      end

      return string_for(ACTIVE)
    end

    def self.for_string(string)
      constants.each do |const|
        return const_get(const) if const.downcase == string.downcase
      end

      return ACTIVE
    end

    # FIXME: These should be model-specific. The original idea that these are general-purpose turned out to be an illusion.
    ACTIVE     = 0
    DELETED    = 1
    LOCKED     = 2
    ARCHIVED   = 3
    UNAPPROVED = 4
    DISABLED   = 5
    PENDING    = 6
  end

  STATES = [
    ['Alabama', 'AL'],
    ['Alaska', 'AK'],
    ['Arizona', 'AZ'],
    ['Arkansas', 'AR'],
    ['California', 'CA'],
    ['Colorado', 'CO'],
    ['Connecticut', 'CT'],
    ['Delaware', 'DE'],
    ['District Of Columbia', 'DC'],
    ['Florida', 'FL'],
    ['Georgia', 'GA'],
    ['Hawaii', 'HI'],
    ['Idaho', 'ID'],
    ['Illinois', 'IL'],
    ['Indiana', 'IN'],
    ['Iowa', 'IA'],
    ['Kansas', 'KS'],
    ['Kentucky', 'KY'],
    ['Louisiana', 'LA'],
    ['Maine', 'ME'],
    ['Maryland', 'MD'],
    ['Massachusetts', 'MA'],
    ['Michigan', 'MI'],
    ['Minnesota', 'MN'],
    ['Mississippi', 'MS'],
    ['Missouri', 'MO'],
    ['Montana', 'MT'],
    ['Nebraska', 'NE'],
    ['Nevada', 'NV'],
    ['New Hampshire', 'NH'],
    ['New Jersey', 'NJ'],
    ['New Mexico', 'NM'],
    ['New York', 'NY'],
    ['North Carolina', 'NC'],
    ['North Dakota', 'ND'],
    ['Ohio', 'OH'],
    ['Oklahoma', 'OK'],
    ['Oregon', 'OR'],
    ['Pennsylvania', 'PA'],
    ['Rhode Island', 'RI'],
    ['South Carolina', 'SC'],
    ['South Dakota', 'SD'],
    ['Tennessee', 'TN'],
    ['Texas', 'TX'],
    ['Utah', 'UT'],
    ['Vermont', 'VT'],
    ['Virginia', 'VA'],
    ['Washington', 'WA'],
    ['West Virginia', 'WV'],
    ['Wisconsin', 'WI'],
    ['Wyoming', 'WY']
  ]
end
