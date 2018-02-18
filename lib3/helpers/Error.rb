module Helper_Error
  def satisfy_class?(object, classes=[String], name=nil, array=false)
    if array
      object = [object] unless object.is_a?(Array)
      object.each do |obj|
        satisfy_class?(obj, name, classes)
      end
    else
      unless classes.include?(obj.class)
        name ||= object.object_id.to_s
        Arango::Error message: "#{name} should be a #{classes.to_s}, not a #{object.class}"
      end
    end
  end

  def satisfy_classes?(objects, classes=[String], array=false)
    objects.each do |object|
      satisfy_class?(object, classes, nil, array)
    end
  end

  def satisfy_category?(object, list)
    unless list.include?(object)
      Arango::Error message "#{name.object_id.to_s} should be part of the list #{list}"
    end
  end

  def ignore_exception
    begin
      yield
    rescue Exception
    end
  end
end
