ActiveSupport::Inflector.class_eval do
  # A more intelligent titleization algorithm.
  # 
  # Rules of capitalization:
  #   1. Don't downcase characters. Acronyms are not words.
  #   2. Upcase a character if it's the first one of the string.
  #   3. Upcase a character if it's preceded by whitespace
  #   4. Upcase a character if it's preceded by an apostrophe followed by whitespace.
  #   5. Upcase a character if it's preceded by an apostrophe, followed by a letter, then whitespace.
  def titleize(word)
    titleized_word = ''
    word.size.times do |i|
      character = word[i, 1]
      if i == 0
        titleized_word << character.capitalize
      elsif i > 1 && word[i - 1, 1] == ' '
        titleized_word << character.capitalize
      elsif i > 2 && word[i - 2, 2] == " '" || word[i - 2, 2] == ' "'
        titleized_word << character.capitalize
      elsif i > 3 && word[i - 3, 3] =~ /[\s][\w][\'\"]/
        titleized_word << character.capitalize
      else
        titleized_word << character
      end
    end
    return titleized_word
  end
end
