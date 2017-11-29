module Helper_Error
  def satisfy_class?(object, name, classes=[String])
    unless classes.include?(object.class)
      Arango::Error message: "#{name} should be a #{classes.to_s}, not a #{object.class}"
    end
  end
end
