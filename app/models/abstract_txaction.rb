# mixin for common txaction functionality between Txaction and InvestmentTxaction
module AbstractTxaction
  extend ActiveSupport::Concern

  included do
    serialize :attachment_ids
    belongs_to :account
    belongs_to :upload
    belongs_to :merged_with_txaction, :class_name => name, :foreign_key => 'merged_with_txaction_id'
    belongs_to :transfer_buddy, :class_name => name, :foreign_key => 'transfer_txaction_id'
  end

  #----------------------------------------------------------------------------
  # Constants
  #
  module Status
    def self.string_for(code)
      constants.each do |const|
        return const.capitalize if const_get(const) == code
      end

      return string_for(DEFAULT)
    end

    def self.for_string(string)
      constants.each do |const|
        return const_get(const) if const.downcase == string.downcase
      end

      return DEFAULT
    end

    ACTIVE     = 0
    DELETED    = 1

    DEFAULT    = ACTIVE
  end

  MAX_ATTACHMENTS = 5
  VISIBLE_STATUSES = [Status::ACTIVE]

  module InstanceMethods
    def visible?
      VISIBLE_STATUSES.include?(status)
    end

    def active?
      status == Status::ACTIVE
    end

    def deleted?
      status == Status::DELETED
    end
  end
end