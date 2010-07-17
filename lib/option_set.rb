# base for "smart" constant classes
#
#   class User
#     # values for status column
#     class Status < OptionSet
#       ACTIVE = 0
#       DELETED = 1
#       PANTS = 2
#     end
#   end
# #
#   >User::Status::PANTS
#   # => 2
#   >User::Status["Pants"]
#   # => 2
#   >User::Status[2]
#   # => "PANTS"
#   >User::Status.options_for_select
#   # => [["Active", 0], ["Deleted", 1], ["Pants", 2]]
class OptionSet
  def self.[](id)
    if id.is_a?(Fixnum)
      return local_constants.find {|c| id == const_get(c)}
    else
      return const_get(id.upcase)
    end
  end

  def self.options_for_select
    local_constants.map {|c| [c.titlecase, const_get(c)]}.sort_by {|c| c[1]}
  end

  private

  def self.local_constants
    constants - superclass.constants
  end
end
