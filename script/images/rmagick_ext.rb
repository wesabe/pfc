class Magick::Image
  def resize_to_square!(new_size)
    width, height = self.columns, self.rows
    if width > height
      self.scale!(new_size / height.to_f)
      # crop 1/3 over from left
      self.crop!((self.columns - new_size) / 3, 0, new_size, new_size, true)
    else
      self.scale!(new_size/width.to_f)
      # crop 1/3 down from top
      self.crop!(0,(self.rows - new_size) / 3, new_size, new_size, true)
    end
  end
end
