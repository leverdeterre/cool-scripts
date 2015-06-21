#!/usr/bin/ruby

DEBUG = true

def extract_function_parameters(one_line)
  params = Array.new
  one_line.scan(/\([a-zA-Z \*]*\)/).each{ |one|
    params.push(clean_string(one))
  }
  return params
end

def extract_function_name(one_line)
  one_line.scan(/\)[ ]*[_a-zA-Z]*:?/).each{ |one|
    return one
  }
  return ""
end

def clean_string(one_string)
  one_string = one_string.gsub(/[ \(\)\*]*/, '')
  return one_string
end

def extract_propery_class(one_line)
  one_line.scan(/\)[ ]*[_a-zA-Z]*:?/).each{ |one|
    return one
  }
  return ""
end

def extract_interface_name(one_line)
  one_line.scan(/[a-zA-Z]* : [a-zA-Z]*/).each{ |one|
    return one
  }
  
  one_line.scan(/[a-zA-Z]*[ ]*\([a-zA-Z]*\)[ ]*<.*>?*/).each{ |one|
    return one
  }
  
  one_line.scan(/[a-zA-Z]*[ ]*\([a-zA-Z]*\)/).each{ |one|
    return one
  }
  return ""
end

def extract_implementation_name(one_line)
  one_line.scan(/ [a-zA-Z]*/).each{ |one|
    return one
  }
  return ""
end


@inheritsFrom = Hash.new()

def analyse_file(filepath)
  
  lines = File.readlines(filepath)
  #puts "#{lines}"

  parsing_interface = false
  parsing_interface_name = nil

  parsing_private_category = false

  lines.each { |one_line| 
   #PARSING INTERFACE
    if one_line.include?"@interface"
      parsing_interface = true
      parsing_interface_name = extract_interface_name(one_line)
      if DEBUG 
        puts "Start parsing interface #{parsing_interface_name}"
      end
      
      if parsing_interface_name.include?":"
        parts = parsing_interface_name.split(":")
        @inheritsFrom[parts[0].gsub(" ","")] = parts[1].gsub(" ","")
        if DEBUG 
          puts "@inheritsFrom #{parts[0].gsub(" ","")} -> #{parts[1].gsub(" ","")}"
        end
      end
  
    elsif parsing_interface and one_line.include?"@end"
      parsing_implementation = false
      if DEBUG 
        puts "End parsing interface #{parsing_interface_name}"
      end
    end   
  }
end

Dir.entries(ARGV[0]).each { |f| 
  if ( f =~ /\.m|\.h/ )
    filepath = "#{ARGV[0]}/#{f}"
    analyse_file(filepath) 
  end
}


#Add missing dependencies
@inheritsFrom["UIView"] = "NSObject";
@inheritsFrom["UIViewController"] = "NSObject";
@inheritsFrom["UITableViewCell"] = "UIView";
@inheritsFrom["UICollectionViewCell"] = "UIView";

def save_into_files()
  File.open('heritage.js', 'w') { |file| 
    @file = file
    #name = "NSObject"
    childs = Hash.new
    @inheritsFrom.each { |key,value|
      array = childs[value]
      if array == nil
        array = Array.new
      end
      
      array.push(key)
      childs[value] = array
    }
    
    save_class("NSObject",childs["NSObject"],childs)
   }
end

def save_class(classname, children, all_children)
  puts "save_class #{classname} children #{children}"
  @file.write("{\n")
  @file.write("\"name\":\"#{classname}\",")
  @file.write("\"size\":10")
  if children
    @file.write(",\n")
    @file.write("\"children\":\n")
    @file.write("[\n")
    children.each{ |child|
      save_class(child,all_children[child],all_children)
      if children.last == child
      else 
        @file.write(",\n")
      end 
    }
    @file.write("]\n")
  end
  @file.write("}\n")

end

save_into_files()
