class Target < ActiveRecord::Base
  attr_protected :user_id

  module Modes
    LIMIT = 0
    TARGET = 1
  end

  belongs_to :tag
  belongs_to :user

  validates_numericality_of :amount_per_month
  validates_presence_of :tag
  validates_presence_of :tag_name
  validates_presence_of :user

  attr_accessor :amount_spent

  def self.for_tag(tag, user)
    tag = Tag.find_by_name(tag) if tag.kind_of?(String)
    Target.find_by_tag_id_and_user_id(tag.id, user.id) if tag
  end

  # set this tag for this target
  def tag=(tag)
    self.tag_id = tag.id
    self.tag_name = tag.name
  end

  def percent_spent
    calculate_percent(@amount_spent, amount_per_month)
  end

  def calculate!(user, period=nil)
    period ||= begin
      start = Time.now.beginning_of_month
      start..(start.end_of_month)
    end

    tag = TagsSpendingSummary.calculate_spending_summary(
      user,
      :period => period,
      :tags => self.tag,
      :type => :txaction,
      :ignore_transfers => false
    ).first
    @amount_spent = (tag ? tag.total_spending.abs : 0)
  end

  def projected_amount_spent
    @amount_spent / (Time.now.day.to_d / Time.now.end_of_month.day.to_d)
  end

  def projected_percent_spent
    calculate_percent(projected_amount_spent, amount_per_month)
  end

  def amount_remaining
    left = amount_per_month - @amount_spent
    left = 0 if left <= 0
    return left
  end

  def status
    if mode == Modes::LIMIT
      'left'
    else
      'to go'
    end
  end

  def good?
    (percent_spent >= 100) ^ (mode == Modes::LIMIT)
  end

private

  def calculate_percent(numerator, divisor)
    x = (numerator.to_f / divisor.to_f) * 100
    raise ZeroDivisionError if x.infinite? || x.nan?
    return x.to_i
  rescue ZeroDivisionError
    return 0
  end

end
