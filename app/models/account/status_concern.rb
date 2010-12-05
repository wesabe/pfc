class Account
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
    ARCHIVED   = 3
    DISABLED   = 5

    DEFAULT    = ACTIVE
    VISIBLE    = [ACTIVE, ARCHIVED]
  end

  MAX_ATTACHMENTS = 5

  def visible?
    VISIBLE_STATUSES.include?(status)
  end

  def active?
    status == ACTIVE
  end

  def active!
    update_attribute :status, Status::ACTIVE
  end

  def deleted?
    status == DELETED
  end

  def deleted!
    update_attribute :status, Status::DELETED
  end

  def archived?
    status == Status::ARCHIVED
  end

  def archived!
    update_attribute :status, Status::ARCHIVED
  end

  def disabled?
    status == Status::DISABLED
  end

  def disabled!
    update_attribute :status, Status::DISABLED
  end
end