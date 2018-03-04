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
          raise Arango::Error.new err: :wrong_class, data: {"wrong_value" => name,
            "wrong_class" => object.class.to_s, "expected_class" => classes.to_s}
        end
      end
    end

    def satisfy_category?(object, list)
      unless list.include?(object)
        name = name.object_id.to_s
        raise Arango::Error.new err: :wrong_element, data: {"wrong_attribute" => name,
          "wrong_value" => object, "list" => list}
      end
    end

    def warning_deprecated(warning, name)
      puts "ARANGORB WARNING: #{name} function is deprecated" if warning
    end
  end
end
