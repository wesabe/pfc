require 'test_helper'

class TxactionNoticesTest < ActionMailer::TestCase
  test "too_big" do
    mail = TxactionNotices.too_big
    assert_equal "Too big", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "duplicate" do
    mail = TxactionNotices.duplicate
    assert_equal "Duplicate", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
