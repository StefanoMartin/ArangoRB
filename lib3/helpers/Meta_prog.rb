module Meta_prog
  def typesafe_accessor(name, classes=[String])
    define_method(name) do
      instance_variable_get("@#{name}")
    end

    define_method("#{name}=") do |value|

      if classes.include?(value.class)
        instance_variable_set("@#{name}", value)
      else
        raise Arango::Error message: "#{name} should be a #{type.to_s}, not a #{value.class}"
      end
    end
  end

  def listsafe_accessor(name, list)
    define_method(name) do
      instance_variable_get("@#{name}")
    end

    define_method("#{name}=") do |value|
      if list.include?(name)
        instance_variable_set("@#{name}", value)
      else
        raise Arango::Error message "#{name.object_id.to_s} should be part of the list #{list}"
      end
    end
  end
end
