module Arango
  module Helper_Error
    def satisfy_class?(object, classes=[String], array=false)
      if array
        object = [object] unless object.is_a?(Array)
        object.each do |obj|
          satisfy_class?(obj, classes, false)
        end
      else
        unless classes.include?(object.class)
          name ||= object.object_id.to_s
          raise Arango::Error.new message: "#{name} should be a #{classes.to_s}, not a #{object.class}"
        end
      end
    end

    def satisfy_category?(object, list)
      unless list.include?(object)
        raise Arango::Error.new message "#{name.object_id.to_s} should be part of the list #{list}"
      end
    end

    def ignore_exception
      begin
        yield
      rescue Exception
      end
    end

    def warning_deprecated(warning, name)
      if warning
        puts "ARANGORB WARNING: #{name} function is deprecated"
      end
    end
  end
end
