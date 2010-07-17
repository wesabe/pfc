# This should be moved into the lib directory.
class UploadAccountInfo < ActiveForm
  attr_accessor :type, :account_number, :balance
  validates_presence_of :type, :account_number
  validates_presence_of :balance
end