class TxactionType < ActiveRecord::Base
  has_many :txactions

  validates_uniqueness_of :name
  validates_presence_of   :name

  def self.find_by_name(name)
    return self.find(:first, :conditions => ["name = ?", name])
  end

  # find the given item by name or create it if it doesn't exist
  def self.find_or_new_by_name(name)
    return self.find_by_name(name) || self.new(:name => name)
  end

end
