require 'digest/md5'
class String
  # Converts a string into a usable DOM id/variable name.
  def as_id
    x = self.gsub(/[^A-Za-z0-9\-_\s]/,'').gsub(/(\s+|\-+)/,'_').downcase
    if x.blank?
      "id_#{Digest::MD5.hexdigest(self).first(10)}"
    else
      if x[0].chr !~ /^[a-z]/i
        'id_' + x
      else
        x
      end
    end
  end
end