# encoding: utf-8
module ToRegexp
  module Regexp
    def to_regexp
      self
    end
  end

  module String
    class << self
      def literal?(str)
        REGEXP_DELIMITERS.none? { |s, e| str.start_with?(s) and str =~ /#{e}#{INLINE_OPTIONS}\z/ }
      end
    end

    INLINE_OPTIONS = /[imxnesu]*/
    REGEXP_DELIMITERS = {
      '%r{' => '}',
      '/' => '/',
    }

    # Get a regexp back
    #
    # Without :literal or :detect, `"foo".to_regexp` will return nil.
    #
    # @param [optional, Hash] options
    # @option options [true,false] :literal Treat meta characters and other regexp codes as just text; always return a regexp
    # @option options [true,false] :detect If string starts and ends with valid regexp delimiters, treat it as a regexp; otherwise, interpret it literally
    # @option options [true,false] :ignore_case /foo/i
    # @option options [true,false] :multiline /foo/m
    # @option options [true,false] :extended /foo/x
    # @option options [true,false] :lang /foo/[nesu]
    def to_regexp(options = {})
      if args = as_regexp(options)
        ::Regexp.new(*args)
      end
    end

    # Return arguments that can be passed to `Regexp.new`
    # @see to_regexp
    def as_regexp(options = {})
      unless options.is_a?(::Hash)
        raise ::ArgumentError, "[to_regexp] Options must be a Hash"
      end
      str = self

      return if options[:detect] and str == ''

      if options[:literal] or (options[:detect] and ToRegexp::String.literal?(str))
        content = ::Regexp.escape str
      elsif delim_set = REGEXP_DELIMITERS.detect { |k, _| str.start_with?(k) }
        delim_start, delim_end = delim_set
        /\A#{delim_start}(.*)#{delim_end}(#{INLINE_OPTIONS})\z/u =~ str
        content = $1
        inline_options = $2
        return unless content.is_a?(::String)
        content.gsub! '\\/', '/'
        if inline_options
          options[:ignore_case] = true if inline_options.include?('i')
          options[:multiline] = true if inline_options.include?('m')
          options[:extended] = true if inline_options.include?('x')
        end
      else
        return
      end

      ignore_case = options[:ignore_case] ? ::Regexp::IGNORECASE : 0
      multiline = options[:multiline] ? ::Regexp::MULTILINE : 0
      extended = options[:extended] ? ::Regexp::EXTENDED : 0

      options_flag = ignore_case | multiline | extended
      [content, options_flag]
    end
  end
end

::String.send :include, ::ToRegexp::String
::Regexp.send :include, ::ToRegexp::Regexp
