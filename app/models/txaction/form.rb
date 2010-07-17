require 'set'

# Handles updating (and creating) transactions based on a hash
# of parameters, most likely the +params+ hash from a controller.
#
# This class makes some assumptions:
#
#   1. only one validation error will be required at a time
#   2. updating a Txaction should be all-or-nothing
#   3. presence of a key indicates a desire to change a value,
#      and absense indicates a desire to leave it unchanged (or default)
#
# Validation errors are communicated as exceptions (+Txaction::Form::UpdateValidationFailed+).
class Txaction::Form
  # The parameters this instance was initialized with (frozen).
  #
  # @return [Hash] Key-value pair to use when updating/creating +Txaction+s.
  attr_reader :params
  # Allows setting the amount and date when it should not be read from +params+.
  attr_writer :amount, :date_posted

  # Encapsulates a validation error that occurred while trying to change a +Txaction+.
  class UpdateValidationFailed < RuntimeError
    # The key of the field that failed validation.
    attr_reader :field
    # The human-readable message explaining why validation failed.
    attr_reader :message

    def initialize(field, message)
      @field, @message = field, message
    end
  end

  def initialize(params={})
    @params = params.dup.freeze
  end

  # Updates the given +txaction+ according to +params+.
  #
  # @param [Txaction] txaction
  #   The txaction to update.
  #
  # @raise [Txaction::Form::UpdateValidationFailed]
  #   When validation fails, this will tell you what field it was and why.
  #
  # @return [Txaction::Form]
  #   Returns +self+.
  def update(txaction)
    Txaction.transaction do
      update_date(txaction)
      update_amount(txaction)
      update_merchant(txaction)
      update_tags(txaction)
      update_transfer_status(txaction)
      update_note(txaction)
    end

    return self
  end

  # Updates the given +txaction+ according to +params+.
  #
  # @param [Txaction] txaction
  #   The txaction to update.
  #
  # @param [Hash] params
  #   The parameters to use to update +txaction+.
  #
  # @raise [Txaction::Form::UpdateValidationFailed]
  #   When validation fails, this will tell you what field it was and why.
  #
  # @return [Txaction::Form]
  #   Returns the new +Txaction::Form+ (which did the update).
  def self.update(txaction, params)
    new(params).update(txaction)
  end

  ## amount ##

  # If necessary, updates +txaction+ according to the amount given in +params+.
  #
  # @param [Txaction] txaction
  #   The txaction to update.
  #
  # @raise [Txaction::Form::UpdateValidationFailed]
  #   If +txaction+ is not a manual transaction it cannot be updated, and this
  #   error will be raised saying so.
  def update_amount(txaction)
    if amount_given? && txaction.manual_txaction?
      validate_amount
      txaction.update_attributes!(:amount => amount)
    end
  end

  # Determines whether +params+ contains an amount.
  #
  # @return [Boolean]
  #   +true+ if +params+ contains an amount, +false+ otherwise.
  def amount_given?
    params.has_key?(:amount)
  end

  # Validates that the amount is present.
  #
  # @raise [Txaction::Form::UpdateValidationFailed]
  #   Raised when the amount in +params+ is blank.
  def validate_amount
    if params[:amount].blank?
      update_error('amount', 'Please enter an amount.')
    end
  end

  # Retrieves the amount from +params+.
  #
  # @return [BigDecimal]
  #   The amount as parsed from +params+.
  def amount
    @amount ||= begin
      amount = Txaction.calculate_amount(params[:amount]).to_d.abs
      amount = -amount if params[:amount_type] == 'spent'
      amount
    end
  end

  ## date posted ##

  # If necessary, updates +txaction+ according to the date given in +params+.
  #
  # @param [Txaction] txaction
  #   The txaction to update.
  #
  # @raise [Txaction::Form::UpdateValidationFailed]
  #   Raised if the date cannot be parsed or is blank.
  def update_date(txaction)
    debugger
    if date_given?
      validate_date

      # only update the date of the txaction if the date has changed--this saves
      # a bit of work and avoids resetting the time portion to 00:00:00, which could
      # cause transaction ordering to change.
      if !txaction.date_posted || (date_posted.to_date != txaction.date_posted.to_date)
        # set it to now if it is today -- preserves the order of cash txaction entry
        self.date_posted = Time.now if date_posted.to_date == Date.today
        txaction.update_attributes!(:date_posted => date_posted)
      end
    end
  end

  # Whether or not +params+ has a date.
  #
  # @return [Boolean]
  #   +true+ if +params+ has a date, +false+ otherwise.
  def date_given?
    params.has_key?(:date_posted)
  end

  # Validates that the date in +params+ is valid.
  #
  # @raise [Txaction::Form::UpdateValidationFailed]
  #   Raised if the date is blank or if it cannot be parsed.
  def validate_date
    if params[:date_posted].blank?
      update_error('date_posted', 'Please enter a date.')
    elsif date_posted.nil?
      update_error('date_posted',
        'We could not parse the date you entered. Please use the format "yyyy-mm-dd".')
    else
      year = date_posted.year
      # FIXME: This is not very DRY, as Txaction does this validation. We should
      # probably move date validation to the Txaction model
      if year < 1920 || year > 9999
        update_error('date_posted', "The date is not valid. Please enter a year between 1920 and 9999.")
      end
    end
  end

  # Parses the date from +params+.
  #
  # @return [Date]
  #   The date as read from +params+.
  def date_posted
    @date_posted ||= begin
      case raw = params[:date_posted].strip
      when %r{^(\d{1,2})[./-](\d{1,2})$} # if they excluded the year, add it for them
        raw = [$1,$2,Time.now.year].join("/")
      end
      time = Chronic.parse(raw)
      time && time.to_date
    end
  end

  # Updates +txaction+ with the merchant given in +params+.
  #
  # @param [Txaction] txaction
  #   The txaction to update.
  #
  # @raise [Txaction::Form::UpdateValidationFailed]
  #   Raised if the merchant name is blank
  def update_merchant(txaction)
    return unless merchant_given?

    if merchant_name.blank?
      # a merchant name is required for manual transactions. For other transactions,
      # a blank merchant name just removes the merchant and we revert to bank puke
      if txaction.manual_txaction?
        update_error('merchant_name', 'Please enter a merchant name.')
      else
        txaction.merchant = nil
        return
      end
    end

    # if the merchant name ends in a slash, consider it unedited (but don't keep the slash in the merchant name)
    unedited = !!(merchant_name.gsub!(/\/+\s*$/, '')) ||
      (txaction.is_check? && (merchant_name.casecmp(txaction.display_name) == 0))

    # if the merchant name starts with a !, only apply the edit to this transaction
    if merchant_name.gsub!(/^!/,'')
      txaction.edit_independently = true
    end

    merchant = Merchant.find_or_create_by_name(merchant_name, :unedited => unedited)

    # update unedited attribute on this merchant if it is now edited
    if merchant.unedited && !unedited
      merchant.update_attribute(:unedited, false)
    end

    txaction.merchant = merchant
  end

  def merchant_given?
    params.has_key?(:merchant_name)
  end

  def merchant_name
    params[:merchant_name]
  end

  def update_tags(txaction)
    txaction.tag_this_and_merchant_untagged_with(params[:tags]) if params[:tags]
  end

  ## transfer ##

  # If necessary, updates +txaction+ according to the transfer status given in +params+.
  #
  # @param [Txaction] txaction
  #   The txaction to update.
  def update_transfer_status(txaction)
    if transfer_given?
      # make a note of the transfer buddy, if it already has one
      if is_transfer?
        buddy = transfer_buddy || txaction
        buddy = txaction if buddy.account.user != txaction.account.user
        txaction.set_transfer_buddy!(buddy)
      else
        txaction.clear_transfer_buddy!
      end
    end
  end

  # Whether +params+ contains an indication of whether or not this is a transfer.
  #
  # @return [Boolean]
  #   +true+ if +params+ indicates that the +Txaction+ has a transfer buddy or is a standalone transfer.
  def transfer_given?
    params.has_key?(:is_transfer) || params.has_key?(:transfer_buddy)
  end

  # Whether +params+ indicates that the +Txaction+ is a transfer.
  #
  # @return [Boolean]
  #   +true+ if the Txaction is explicitly marked a transfer or implicitly by having a buddy,
  #   or +false+ if neither is the case.
  def is_transfer?
    case params[:is_transfer]
    when '1', 't', 'true', 'on'
      return true
    when '0', 'f', 'false', 'off'
      return false
    else
      return (not transfer_buddy.nil?)
    end
  end

  # Returns the transfer buddy referenced by +params+.
  #
  # @return [Txaction, nil]
  #   Returns a +Txaction+ if there is one as given in +params+, +nil+ otherwise.
  def transfer_buddy
    @transfer_buddy ||= begin
      if params.has_key?(:transfer_buddy)
        Txaction.find_by_id(params[:transfer_buddy])
      end
    end
  end

  ## note ##

  # If necessary, updates +txaction+ according to the note given in +params+.
  #
  # @param [Txaction] txaction
  #   The txaction to update.
  def update_note(txaction)
    if note_given?
      txaction.update_attributes!(:note => params[:note])
    end
  end

  # Whether +params+ contains a note.
  #
  # @return [Boolean]
  #   +true+ if +params+ contains a note, +false+ otherwise.
  def note_given?
    params.has_key?(:note)
  end

  private

  def update_error(field, message)
    raise UpdateValidationFailed.new(field, message)
  end
end
