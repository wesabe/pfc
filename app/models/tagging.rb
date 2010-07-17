class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  belongs_to :txaction, :class_name => 'Txaction',
                        :foreign_key => 'taggable_id'
  belongs_to :merchant, :class_name => 'Merchant',
                        :foreign_key => 'taggable_id'
  belongs_to :goal, :class_name => 'Goal',
                    :foreign_key => 'taggable_id'
  belongs_to :goal_membership, :class_name => 'GoalMembership',
                               :foreign_key => 'taggable_id'

  after_save :set_tagged_flag
  after_destroy :clear_tagged_flag

  validates_presence_of :name

  def set_tagged_flag
    # set the tagged column of the taggable if it exists (right now
    # only for Txactions); this allows fast lookup of untagged items)
    if taggable && taggable.respond_to?(:tagged) && !taggable.tagged
      taggable.tagged = true
      taggable.class.update_all("tagged = 1", ["id = ?", taggable.id])
    end
  end

  def clear_tagged_flag
    # unset the tagged column of the taggable if it exists (right now only for Txactions)
    if taggable && taggable.respond_to?(:tagged) && taggable.tagged && taggable.tags.count == 0
      taggable.tagged = false
      # see note in set_tagged_flag
      taggable.class.update_all("tagged = 0", ["id = ?", taggable.id])
    end
  end

  def self.tagged_class(taggable)
    ActiveRecord::Base.send(:class_name_of_active_record_descendant, taggable.class).to_s
  end

  def self.find_taggable(tagged_class, tagged_id)
    tagged_class.constantize.find(tagged_id)
  end

  # format a split amount to it's simplest possible representation, either ##
  # or ##.##
  def split_amount_display
    currency = taggable.respond_to?(:currency) ? taggable.currency : nil
    Currency.format(split_amount.abs, currency, :hide_unit => true).sub(/[.,]00$/,'')
  end

  # display the tagging either as tag or tag:split_amount; quote it if it contains spaces
  def display_name
    quoted_name = (name =~ /\s/) ? %{"#{name}"} : name
    read_attribute(:split_amount) ? "#{quoted_name}:#{split_amount_display}" : quoted_name
  end

  def normalized_name
    Tag.normalize(name)
  end

  def to_param
    param = name.dup
    Tag::OUTGOING_URL_ESCAPES.each{|o,s| param.gsub!(o,s) }
    param
  end

end
