class User::DestroyUser
  @queue = :low

  def self.perform(id)
    user = User.find_by_id(id)
    user.destroy if user
  end
end