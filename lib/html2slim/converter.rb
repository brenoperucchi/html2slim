require_relative 'hpricot_monkeypatches'

module HTML2Slim
  class Converter
    def to_s
      @slim
    end
  end
  class HTMLConverter < Converter
    def initialize(html)
      @slim = Hpricot(html).to_slim
    end
  end
  class ERBConverter < Converter

    def remove_break_lines(erb)
      count_brackets = 0
      erb_modified = erb.each_line.map do |line|
        count_brackets += line.count("(") - line.count(")")
        if count_brackets > 0
          line.gsub!(/\s+/, '')  # Remove all whitespace
          line.gsub!(/,/, ', ')  # Add a space after each comma
          line.chomp!            # Remove the newline at the end
        end
        line
      end.join
      erb_modified
    end

    def initialize(file)
      # open.read makes it works for files & IO
      erb = File.exist?(file) ? open(file).read : file

      erb = remove_break_lines(erb)

      erb.gsub!(/<%(.+?)\s*\{\s*(\|.+?\|)?\s*%>/){ %(<%#{$1} do #{$2}%>) }
      # case, if, for, unless, until, while, and blocks...
      erb.gsub!(/<%(-\s+)?((\s*(case|if|for|unless|until|while) .+?)|.+?do\s*(\|.+?\|)?\s*)-?%>/){ %(<ruby code="#{$2.gsub(/"/, '&quot;')}">) }
      # else
      erb.gsub!(/<%-?\s*else\s*-?%>/, %(</ruby><ruby code="else">))
      # elsif
      erb.gsub!(/<%-?\s*(elsif .+?)\s*-?%>/){ %(</ruby><ruby code="#{$1.gsub(/"/, '&quot;')}">) }
      # when
      erb.gsub!(/<%-?\s*(when .+?)\s*-?%>/){ %(</ruby><ruby code="#{$1.gsub(/"/, '&quot;')}">) }
      erb.gsub!(/<%\s*(end|}|end\s+-)\s*%>/, %(</ruby>))
      erb.gsub!(/<%-?(.+?)\s*-?%>/m){ %(<ruby code="#{$1.gsub(/"/, '&quot;')}"></ruby>) }
      @slim ||= Hpricot(erb).to_slim
    end
  end
end
