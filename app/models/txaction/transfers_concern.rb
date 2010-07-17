# transfers concern for Txaction
class Txaction
  before_destroy :clear_transfer_buddy!

  def find_all_matching_transfers
    if date_posted.nil? || amount == 0
      # we can't match it if we don't have a time-frame or a zero amount
      return []
    end
    other_account_ids = account.user.accounts.visible.map(&:id) - [account.id]
    if other_account_ids.blank?
      []
    else
      Txaction.find(:all, :conditions => [
        %{ account_id in (?) AND amount = ?
           AND date_posted BETWEEN ? AND ?
           AND status IN (?) },
           other_account_ids, -(amount),
           date_posted - 3.weeks, date_posted + 3.weeks,
           [Constants::Status::ACTIVE, Constants::Status::PENDING]])
    end
  end

  def find_matching_transfer
    #found a rough set
    buddies = find_all_matching_transfers

    # filter to tighter matching for automatic
    buddies.reject! do |txaction|
      # transactions on lines of credit and brokerage accts aren't transfers
      [AccountType::CREDITLINE, AccountType::BROKERAGE].include?(txaction.account.account_type_id) ||
      # filter by a narrower range when trying to be automatic
      # not sure why the to_time is needed
      txaction.date_posted > (self.date_posted.to_time + 1.week) ||
      txaction.date_posted < (self.date_posted.to_time - 1.week)
    end

    return nil if buddies.empty?
    return buddies[0] if buddies.size < 2

    # dupes?
    names = buddies.map{|b| b.filtered_name}
    if names.uniq.size == 1 && !(names[0].nil?)
      # they're dupes, so it doesn't matter which we pick
      return buddies[0]
    end

    match_expression = /transfer|xfer|from|to/i
    xfers = buddies.find_all { |tx| tx.merchant_name =~ match_expression || tx.filtered_name =~ match_expression }

    return xfers[0] if xfers.size == 1

    # find the closer one
    in_order = buddies.sort_by {|buddy| (buddy.date_posted.to_time - self.date_posted.to_time).abs}
    if((in_order[1].date_posted - in_order[0].date_posted).abs >= 2.day)
      # one tx is closer by more than two days, it's probably the one
      return in_order[0]
    end

    # Give up and let the user figure it out
    return nil
  end

  def attach_matching_transfer
    return if transfer_txaction_id

    if buddy = find_matching_transfer
      # now buddy is found, ask it if it sees dupes
      if buddy.find_matching_transfer == self
        set_transfer_buddy!(buddy)
        return buddy
      elsif buddy.find_matching_transfer.nil? # this txaction is causing ambiguity
        buddy.clear_transfer_buddy!
      end
    end

    return nil
  end

  def transfer?
    true if transfer_txaction_id
  end

  # true if this txaction has a transfer buddy that isn't itself
  def paired_transfer?
    transfer_buddy && transfer_buddy != self
  end

  # connect or sever a transfer buddy
  def set_transfer_buddy!(txaction)
    Txaction.transaction do
      if transfer_buddy == txaction
        # nothing to change
        return
      elsif transfer_buddy && transfer_buddy.transfer_buddy == self
        # unlink buddy as a transfer
        transfer_buddy.update_attribute(:transfer_txaction_id, nil)
      elsif transfer_buddy
        # transfer buddy doesn't think he's my buddy, just leave him alone
      end

      if txaction == self
        # non-paired transfer
        self.update_attribute(:transfer_txaction_id, self.id)
      elsif txaction
        # paired transfer

        if txaction.transfer_buddy
          # new buddy already has a buddy, so break that connection first
          txaction.transfer_buddy.set_transfer_buddy!(txaction.transfer_buddy)
        end

        self.update_attribute(:transfer_txaction_id, txaction.id)
        txaction.update_attribute(:transfer_txaction_id, self.id)
      elsif not destroyed?
        # non-transfer
        self.update_attribute(:transfer_txaction_id, nil)
      end
    end
  end

  def mark_as_unpaired_transfer!
    set_transfer_buddy!(self)
  end

  # convenience method for severing a transfer link
  def clear_transfer_buddy!
    set_transfer_buddy!(nil)
  end
end
