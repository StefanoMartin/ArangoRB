module Helper_Error
  def is_a_string?(string, name)
    unless string.is_a?(String)
      Arango::Error message: "#{name} should be a String, not a #{string.class}"
    end
  end
end
