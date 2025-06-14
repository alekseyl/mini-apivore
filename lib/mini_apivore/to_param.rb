# frozen_string_literal: true

require "cgi"

unless Object.method_defined?(:to_param)
  class Object
    # Alias of <tt>to_s</tt>.
    def to_param
      to_s
    end

    # Converts an object into a string suitable for use as a URL query string,
    # using the given <tt>key</tt> as the param name.
    def to_query(key)
      "#{CGI.escape(key.to_param)}=#{CGI.escape(to_param.to_s)}"
    end
  end
end

unless NilClass.method_defined?(:to_param)
  class NilClass
    # Returns +self+.
    def to_param
      self
    end
  end
end

unless TrueClass.method_defined?(:to_param)
  class TrueClass
    # Returns +self+.
    def to_param
      self
    end
  end
end

unless FalseClass.method_defined?(:to_param)
  class FalseClass
    # Returns +self+.
    def to_param
      self
    end
  end
end

unless Array.method_defined?(:to_param)
  class Array
    # Calls <tt>to_param</tt> on all its elements and joins the result with
    # slashes. This is used by <tt>url_for</tt> in Action Pack.
    def to_param
      collect(&:to_param).join("/")
    end

    # Converts an array into a string suitable for use as a URL query string,
    # using the given +key+ as the param name.
    #
    #   ['Rails', 'coding'].to_query('hobbies') # => "hobbies%5B%5D=Rails&hobbies%5B%5D=coding"
    def to_query(key)
      prefix = "#{key}[]"

      if empty?
        nil.to_query(prefix)
      else
        collect { |value| value.to_query(prefix) }.join("&")
      end
    end
  end
end

unless Hash.method_defined?(:to_param)
  class Hash
    # Returns a string representation of the receiver suitable for use as a URL
    # query string:
    #
    #   {name: 'David', nationality: 'Danish'}.to_query
    #   # => "name=David&nationality=Danish"
    #
    # An optional namespace can be passed to enclose key names:
    #
    #   {name: 'David', nationality: 'Danish'}.to_query('user')
    #   # => "user%5Bname%5D=David&user%5Bnationality%5D=Danish"
    #
    # The string pairs "key=value" that conform the query string
    # are sorted lexicographically in ascending order.
    #
    # This method is also aliased as +to_param+.
    def to_query(namespace = nil)
      collect do |key, value|
        unless (value.is_a?(Hash) || value.is_a?(Array)) && value.empty?
          value.to_query(namespace ? "#{namespace}[#{key}]" : key)
        end
      end.compact.sort! * "&"
    end

    alias to_param to_query
  end
end
