class TxactionAttachment < ActiveRecord::Base
  belongs_to :attachment
  belongs_to :txaction
end