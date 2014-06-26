module TutorHelper
  def create_javascript_var(var_name, var_value)
    js = "var #{var_name} = {"
    var_value.each do |key, value|
      js += "#{key.inspect}: #{value.inspect},"
    end
    js += "1: 1 };"
    js
  end
  def truncate(string, length)
    without_html = string.gsub(/`/, '').gsub('"', '&quot;')
    if string.length > length
      truncated = string[0...length]
      "<span title=\"#{without_html}\">#{truncated}...</span>"
    else
      string
    end
  end
end
