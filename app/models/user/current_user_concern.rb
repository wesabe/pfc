# current user concern for User
# allows the currently logged-in user to be accessible from models
class User
  def self.current
    Thread.current[:pfc_user]
  end

  def self.current=(user)
    raise(ArgumentError,
      "Invalid user. Expected an object of class 'User', got #{user.inspect}") if user && !user.is_a?(User)
    Thread.current[:pfc_user] = user
  end
end
