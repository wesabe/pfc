# roles concern for User
class User
  scope :role, lambda {|role| {:conditions => ['(role & ?) > 0', role]} }

  # roles should be a power of two so they can be ANDed together
  class Role
    USER  = 0
    ADMIN = 1
  end

  # return true if the user is an admin
  def admin?
    role & Role::ADMIN > 0
  end

  def admin=(flag)
    _toggle_role(Role::ADMIN, flag)
  end

  # set role directly
  def role=(value)
    write_attribute(:role, value)
  end

private

  # toggle the given role based on flag
  def _toggle_role(role, flag)
    mask = User::Role.constants.inject(0){|m,c| m | User::Role.const_get(c)}
    flag = (flag == true || flag == false) ? flag : %w[1 t true].include?(flag.to_s.downcase)

    if flag
      self.role |= role
    else
      self.role &= (mask ^ role)
    end
  end

end
