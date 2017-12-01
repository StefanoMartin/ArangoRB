module Helper_Error
  def satisfy_class?(object, name, classes=[String])
    unless classes.include?(object.class)
      Arango::Error message: "#{name} should be a #{classes.to_s}, not a #{object.class}"
    end
  end

  def satisfy_category?(object, list)
    unless list.include?(object)
      Arango::Error message "#{name} should be part of the list #{list}"
    end
  end
end
