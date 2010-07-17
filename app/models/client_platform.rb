class ClientPlatform < ActiveRecord::Base
  def self.find_by_name(name)
    return nil if name.nil?
    return self.find(:first, :conditions => ["name = ?", name])
  end

  # find the given item by name or create it if it doesn't exist
  # TODO: refactor this method to a common base class or helper module
  def self.find_or_create_by_name(name)
    return self.find_by_name(name) || self.create(:name => name)
  end
end
