module ActiveRecordMatchers
  # Match against a specific error type at a given ActiveRecord model instance's
  # attribute.
  #
  # Errors are matched using a symbol referencing the error message stored at
  # I18n.translate('activerecord.errors.messages').
  #
  # Possible error types and their messages are are:
  #    :less_than_or_equal_to => "must be less than or equal to %d"
  #                 :accepted => "must be accepted"
  #             :not_a_number => "is not a number"
  #                      :odd => "must be odd"
  #                    :blank => "can't be blank"
  #             :greater_than => "must be greater than %d"
  #                :inclusion => "is not included in the list"
  #                     :even => "must be even"
  #                 :too_long => "is too long (maximum is %d characters)"
  # :greater_than_or_equal_to => "must be greater than or equal to %d"
  #                :exclusion => "is reserved"
  #                :too_short => "is too short (minimum is %d characters)"
  #                 :equal_to => "must be equal to %d"
  #                  :invalid => "is invalid"
  #             :wrong_length => "is the wrong length (should be %d characters)"
  #                :less_than => "must be less than %d"
  #             :confirmation => "doesn't match confirmation"
  #                    :taken => "has already been taken"
  #                    :empty => "can't be empty"
  #
  # Using these identifiers make the code more portable because if you ever change
  # the default messages you won't need to change your specs. But what if you have
  # set a custom message using the :message argument in validations? The quick way is
  # passing the message instead of the error identifier. There's a better approach
  # though. Add a new key/pair value in the default_error_messages hash and use the key
  # as identifier.
  #
  # NOTE: Check the have_error_on method, that is the one you have to use in the specs.
  class HaveErrorOn

    # Creates a new HaveErrorOn matcher instance.
    #
    # Arguments are:
    #   * attribute: the attribute that possible contains the error;
    #   * error_or_message: one of the identifiers described above or the error message expected;
    #   * msg_args: some of the messages uses Kernel#sprintf format to set some arguments,
    #     since what we're actually doing is comparing message you need to provide the arguments
    #     if any exists;
    def initialize(attribute, error_or_message=nil, *msg_args)
      @attribute = attribute
      @error     = error_or_message
      @msg_args  = msg_args
      @message   = ::I18n.translate('activerecord.errors.messages')[error_or_message] || error_or_message
    end

    def matches?(record)
      @record = record
      @errors = !@record.valid? && Array(@record.errors.on(@attribute))
      @message ? @errors.include?(@message % @msg_args) : !@errors.blank? if @errors
    end

    def failure_message
      "expected #{@record.inspect} to have an error (#@error) at attribute '#@attribute', got error(s):\n\t- #{@errors.blank? ? "No errors" : @errors.join("\n\t- ")}"
    end

    def negative_failure_message
      "expected #{@record.inspect} to not have an error at attribute '#@attribute' (#@error)"
    end
  end

  # For a concept description check HaveErrorOn.
  #
  # Usage examples:
  #   it "should require a name" do
  #     person.should have_error_on(:name, :blank)
  #   end
  #
  #   it "should require minimum length of 3 for names" do
  #     person.name = "ab"
  #     person.should have_error_on(:name, :too_short, [3])
  #     person.name = "joe"
  #     person.should_not have_error_on(:name, :too_short, [3])
  #   end
  def have_error_on(*args)
    HaveErrorOn.new(*args)
  end
end