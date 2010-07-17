class ActiveRecord::Base
  def self.latest(what=:first, options={})
    options, what = options.merge(:limit => what), :all if what.is_a?(Fixnum)
    options, what = what, :first if what.is_a?(Hash)
    find(what, options.reverse_merge(:order => "#{table_name}.created_at desc"))
  end
end

