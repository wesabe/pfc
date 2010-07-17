# REVIEW: This should be moved into the lib directory.
# form used in account upload
class UploadAccount < ActiveForm
  attr_accessor :name, :statement

  def validate
    errors.add(:name, "can't be blank") if name.blank?
    errors.add(:statement, "can't be blank") if statement.blank? || statement.original_filename.blank?
  end
end