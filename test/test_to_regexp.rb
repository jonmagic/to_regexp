# encoding: UTF-8
require 'helper'

describe "String#to_regexp" do
  it "compares ASCII string to regular expression" do
    str = "/finalis(e)/im"
    old_way = eval(str)
    new_way = str.to_regexp
    assert_equal old_way, new_way
  end

  it "compares UTF-8 string to regular expression" do
    str = "/finalis(é)/im"
    old_way = eval(str)
    new_way = str.to_regexp
    assert_equal old_way, new_way
  end

  it "matches UTF-8 character in a string" do
    assert_equal 'ë', '/(ë)/'.to_regexp.match('Citroën').captures[0]
  end

  it "matches multiline string to regular expression" do
    assert_nil '/foo.*(bar)/'.to_regexp.match("foo\n\nbar")
    assert_equal 'bar', '/foo.*(bar)/m'.to_regexp.match("foo\n\nbar").captures[0]
  end

  it "matches string to regular expression with ignore case" do
    assert_nil '/(FOO)/'.to_regexp.match('foo')
    assert_equal 'foo', '/(FOO)/i'.to_regexp.match('foo').captures[0]
  end

  it "matches string to regular expression with percentage r notation" do
    assert_equal '/', '%r{(/)}'.to_regexp.match('/').captures[0]
  end

  it "matches multiline string to regular expression with ignore case" do
    assert_equal 'bar', '/FOO.*(BAR)/mi'.to_regexp.match("foo\n\nbar").captures[0]
  end

  it "handles garbled input" do
    if RUBY_VERSION >= '1.9'
      garbled = 'finalisé'.force_encoding('ASCII-8BIT') # like if it was misinterpreted
      assert_raises(Encoding::CompatibilityError) do
        '/finalis(é)/'.to_regexp.match(garbled)
      end
    else # not applicable to ruby 1.8
      garbled = 'finalisé'
      assert_nothing_raised do
        '/finalis(é)/'.to_regexp.match(garbled)
      end
    end
  end

  it "fixes garbled input using Manfred's gem" do
    if RUBY_VERSION >= '1.9'
      require 'ensure/encoding'
      garbled = 'finalisé'.force_encoding('ASCII-8BIT') # like if it was misinterpreted
      assert_equal 'é', '/finalis(é)/'.to_regexp.match(garbled.ensure_encoding('UTF-8')).captures[0]
    else # not applicable to ruby 1.8
      garbled = 'finalisé'
      assert_equal 'é', '/finalis(é)/'.to_regexp.match(garbled).captures[0]
    end
  end

  it "converts string to regular expression with as_regexp method" do
    str = '/finalis(é)/in'
    assert_equal ['finalis(é)', ::Regexp::IGNORECASE, 'n'], str.as_regexp
    assert_equal Regexp.new(*str.as_regexp), str.to_regexp
  end

  it "returns nil when converting a non-regular expression string" do
    assert_nil 'hi'.to_regexp
  end

  it "converts regular expression to regular expression" do
    a = /foo/
    assert_equal a, a.to_regexp
  end

  it "matches string to regular expression with ignore case option" do
    assert_nil '/(FOO)/'.to_regexp(:ignore_case => false).match('foo')
    assert_nil '/(FOO)/'.to_regexp(:ignore_case => false).match('foo')
    assert_equal 'foo', '/(FOO)/'.to_regexp(:ignore_case => true).match('foo').captures[0]
    assert_equal 'foo', '/(FOO)/i'.to_regexp(:ignore_case => true).match('foo').captures[0]
  end

  it "matches string to regular expression with literal option" do
    assert '/(FOO)/'.to_regexp(:literal => true).match('hello/(FOO)/there')
  end

  it "combines literal and ignore case options" do
    assert '/(FOO)/'.to_regexp(:literal => true, :ignore_case => true).match('hello/(foo)/there')

    # can't use inline options obviously
    assert_nil '/(FOO)/i'.to_regexp(:literal => true).match('hello/(foo)/there')
    assert '/(FOO)/i'.to_regexp(:literal => true).match('hello/(FOO)/ithere')
  end

  it "tries to convert string to regular expression" do
    if RUBY_VERSION >= '1.9'
      assert_equal /foo/i, Regexp.try_convert('/foo/i')
      assert_equal //, Regexp.try_convert('//')
    end
  end

  # seen in the wild - from rack-1.2.5/lib/rack/utils.rb - converted to array to preserve order in 1.8.7
  ESCAPE_HTML_KEYS = [
    "&",
    "<",
    ">",
    "'",
    '"',
    "/"
  ]
  it "tests union of regular expressions" do
    assert_equal /penzance/, Regexp.union('penzance')
    assert_equal /skiing|sledding/, Regexp.union('skiing', 'sledding')
    assert_equal /skiing|sledding/, Regexp.union(['skiing', 'sledding'])
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union(/dogs/, /cats/i)
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union('/dogs/', /cats/i)
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union(/dogs/, '/cats/i')
    assert_equal %r{&|<|>|'|"|\/}.inspect, Regexp.union(*ESCAPE_HTML_KEYS).inspect
  end

  it "detects regular expression in a string" do
    assert_nil ''.to_regexp(:detect => true)
    assert_equal //, '//'.to_regexp(:detect => true)
    assert_equal /foo/, 'foo'.to_regexp(:detect => true)
    assert_equal %r{foo\\b}, 'foo\b'.to_regexp(:detect => true)
    assert_equal %r{foo\b}, '/foo\b/'.to_regexp(:detect => true)
    assert_equal %r{foo\\b/}, 'foo\b/'.to_regexp(:detect => true)
    assert_equal %r{foo\b}i, '/foo\b/i'.to_regexp(:detect => true)
    assert_equal %r{foo\\b/i}, 'foo\b/i'.to_regexp(:detect => true)
    assert_equal /FOO.*(BAR)/mi, '/FOO.*(BAR)/mi'.to_regexp(:detect => true)
  end

  # https://github.com/ruby/ruby/blob/trunk/test/ruby/test_regexp.rb#L474 "test_union2"
  it "tests union of regular expressions in MRI" do
    assert_equal(/(?!)/, Regexp.union)
    assert_equal(/foo/, Regexp.union(/foo/))
    assert_equal(/foo/, Regexp.union([/foo/]))
    assert_equal(/\t/, Regexp.union("\t"))
    assert_equal(/(?-mix:\u3042)|(?-mix:\u3042)/, Regexp.union(/\u3042/, /\u3042/))
    assert_equal("\u3041", "\u3041"[Regexp.union(/\u3042/, "\u3041")])
  end

  # https://github.com/ruby/ruby/blob/trunk/test/ruby/test_regexp.rb#L464 "test_try_convert"
  it "tries to convert string to regular expression in MRI" do
    assert_equal(/re/, Regexp.try_convert(/re/))
    assert_nil(Regexp.try_convert("re"))

    o = Object.new
    assert_nil(Regexp.try_convert(o))
    def o.to_regexp() /foo/ end
    assert_equal(/foo/, Regexp.try_convert(o))
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/try_convert_spec.rb#L5
  it "returns argument if given regular expression in JRuby" do
    assert_equal /foo/s, Regexp.try_convert(/foo/s)
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/try_convert_spec.rb#L9
  it "returns nil if given argument can't be converted in JRuby" do
    ['', 'glark', [], Object.new, :pat].each do |arg|
      assert_nil Regexp.try_convert(arg)
    end
  end

  # https://github.com/jruby/jruby/blob/master/test/externals/ruby1.9/uri/test_common.rb#L32
  it "tests URI common regular expression in JRuby" do
    assert_instance_of Regexp, URI.regexp
    assert_instance_of Regexp, URI.regexp(['http'])
    assert_equal URI.regexp, URI.regexp
    assert_equal 'http://', 'x http:// x'.slice(URI.regexp)
    assert_equal 'http://', 'x http:// x'.slice(URI.regexp(['http']))
    assert_equal 'http://', 'x http:// x ftp://'.slice(URI.regexp(['http']))
    assert_nil 'http://'.slice(URI.regexp([]))
    assert_nil ''.slice(URI.regexp)
    assert_nil 'xxxx'.slice(URI.regexp)
    assert_nil ':'.slice(URI.regexp)
    assert_equal 'From:', 'From:'.slice(URI.regexp)
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/union_spec.rb#L14
  it "quotes string arguments in JRuby" do
    assert_equal /n|\./, Regexp.union("n", ".")
  end
end
