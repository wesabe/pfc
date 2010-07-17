class String
  # return the singular version (well, self) if the count is 1, otherwise call pluralize
  # acts similar to ActionView::Helpers::TextHelper::pluralize, but doesn't attach the count to the return string  
  def pluralize_with_count(count = 0)
    count.to_i == 1 ? self : self.pluralize_without_count
  end
  alias_method_chain :pluralize, :count
end