class UploadFormat < ActiveRecord::Base
    # find the given platform or create it if it doesn't exist
  def self.find_or_create_by_name(name)
    find_by_name(name) || create(:name => name)
  end
end
