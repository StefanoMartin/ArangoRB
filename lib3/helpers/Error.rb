module Helper_Error
  def satisfy_class?(object, name, classes=[String], array=false)
    if array
      object = [object] unless object.is_a?(Array)
      object.each do |obj|
        satisfy_class?(obj, name, classes)
      end
    else
      unless classes.include?(obj.class)
        Arango::Error message: "#{name} should be a #{classes.to_s}, not a #{object.class}"
      end
    end
  end

  def satisfy_category?(object, list, name)
    unless list.include?(object)
      Arango::Error message "#{name} should be part of the list #{list}"
    end
  end

  def ignore_exception
    begin
      yield
    rescue Exception
    end
  end
end
