class ActiveRecord::Base
  
  def error_sentence
    errors.full_messages.to_sentence.downcase.capitalize
  end
  
end