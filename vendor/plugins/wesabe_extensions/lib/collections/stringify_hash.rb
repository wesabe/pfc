class Hash
  def stringify
    inject({}) do |options, (key, value)|
      options[key.to_s] = value
      options
    end.sort.flatten.join("-")
  end
end