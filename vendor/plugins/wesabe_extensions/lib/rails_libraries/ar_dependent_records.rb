class ActiveRecord::Base
  def dependent_record_count
    dependent_associations = self.class.reflect_on_all_associations \
      .select { |ar| ar.macro != :belongs_to } \
      .map { |ar| ar.name }
    return dependent_associations.map { |m|
      association = self.send(m)
      if association.respond_to?(:count)
        association.count
      else
        1
      end
    }.inject(0) { |a, b| a + b }
  end
end