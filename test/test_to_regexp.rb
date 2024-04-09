# encoding: UTF-8
require 'helper'

describe "String#to_regexp" do
  it "test_000_versus_eval_ascii" do
    str = "/finalis(e)/im"
    old_way = eval(str)
    new_way = str.to_regexp
    assert_equal old_way, new_way
  end

  it "test_000a_versus_eval_utf8" do
    str = "/finalis(é)/im"
    old_way = eval(str)
    new_way = str.to_regexp
    assert_equal old_way, new_way
  end

  it "test_001_utf8" do
    assert_equal 'ë', '/(ë)/'.to_regexp.match('Citroën').captures[0]
  end

  it "test_002_multiline" do
    assert_nil '/foo.*(bar)/'.to_regexp.match("foo\n\nbar")
    assert_equal 'bar', '/foo.*(bar)/m'.to_regexp.match("foo\n\nbar").captures[0]
  end

  it "test_003_ignore_case" do
    assert_nil '/(FOO)/'.to_regexp.match('foo')
    assert_equal 'foo', '/(FOO)/i'.to_regexp.match('foo').captures[0]
  end

  it "test_004_percentage_r_notation" do
    assert_equal '/', '%r{(/)}'.to_regexp.match('/').captures[0]
  end

  it "test_005_multiline_and_ignore_case" do
    assert_equal 'bar', '/FOO.*(BAR)/mi'.to_regexp.match("foo\n\nbar").captures[0]
  end

  it "test_006_cant_fix_garbled_input" do
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

  it "test_007_possible_garbled_input_fix_using_manfreds_gem" do
    if RUBY_VERSION >= '1.9'
      require 'ensure/encoding'
      garbled = 'finalisé'.force_encoding('ASCII-8BIT') # like if it was misinterpreted
      assert_equal 'é', '/finalis(é)/'.to_regexp.match(garbled.ensure_encoding('UTF-8')).captures[0]
    else # not applicable to ruby 1.8
      garbled = 'finalisé'
      assert_equal 'é', '/finalis(é)/'.to_regexp.match(garbled).captures[0]
    end
  end

  it "test_008_as_regexp" do
    str = '/finalis(é)/in'
    assert_equal ['finalis(é)', ::Regexp::IGNORECASE, 'n'], str.as_regexp
    assert_equal Regexp.new(*str.as_regexp), str.to_regexp
  end

  it "test_009_ruby_19_splat" do
    assert_nil 'hi'.to_regexp
  end

  it "test_010_regexp_to_regexp" do
    a = /foo/
    assert_equal a, a.to_regexp
  end

  it "test_011_ignore_case_option" do
    assert_nil '/(FOO)/'.to_regexp(:ignore_case => false).match('foo')
    assert_nil '/(FOO)/'.to_regexp(:ignore_case => false).match('foo')
    assert_equal 'foo', '/(FOO)/'.to_regexp(:ignore_case => true).match('foo').captures[0]
    assert_equal 'foo', '/(FOO)/i'.to_regexp(:ignore_case => true).match('foo').captures[0]
  end

  it "test_012_literal_option" do
    assert '/(FOO)/'.to_regexp(:literal => true).match('hello/(FOO)/there')
  end

  it "test_013_combine_literal_and_ignore_case" do
    assert '/(FOO)/'.to_regexp(:literal => true, :ignore_case => true).match('hello/(foo)/there')

    # can't use inline options obviously
    assert_nil '/(FOO)/i'.to_regexp(:literal => true).match('hello/(foo)/there')
    assert '/(FOO)/i'.to_regexp(:literal => true).match('hello/(FOO)/ithere')
  end

  it "test_014_try_convert" do
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
  it "test_015_union" do
    assert_equal /penzance/, Regexp.union('penzance')
    assert_equal /skiing|sledding/, Regexp.union('skiing', 'sledding')
    assert_equal /skiing|sledding/, Regexp.union(['skiing', 'sledding'])
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union(/dogs/, /cats/i)
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union('/dogs/', /cats/i)
    assert_equal /(?-mix:dogs)|(?i-mx:cats)/, Regexp.union(/dogs/, '/cats/i')
    assert_equal %r{&|<|>|'|"|\/}.inspect, Regexp.union(*ESCAPE_HTML_KEYS).inspect
  end

  it "test_016_detect" do
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
  it "test_mri_union2" do
    assert_equal(/(?!)/, Regexp.union)
    assert_equal(/foo/, Regexp.union(/foo/))
    assert_equal(/foo/, Regexp.union([/foo/]))
    assert_equal(/\t/, Regexp.union("\t"))
    assert_equal(/(?-mix:\u3042)|(?-mix:\u3042)/, Regexp.union(/\u3042/, /\u3042/))
    assert_equal("\u3041", "\u3041"[Regexp.union(/\u3042/, "\u3041")])
  end

  # https://github.com/ruby/ruby/blob/trunk/test/ruby/test_regexp.rb#L464 "test_try_convert"
  it "test_mri_try_convert" do
    assert_equal(/re/, Regexp.try_convert(/re/))
    assert_nil(Regexp.try_convert("re"))

    o = Object.new
    assert_nil(Regexp.try_convert(o))
    def o.to_regexp() /foo/ end
    assert_equal(/foo/, Regexp.try_convert(o))
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/try_convert_spec.rb#L5
  it "test_jruby_returns_argument_if_given_regexp" do
    assert_equal /foo/s, Regexp.try_convert(/foo/s)
  end

  # https://github.com/jruby/jruby/blob/master/spec/ruby/core/regexp/try_convert_spec.rb#L9
  it "test_jruby_returns_nil_if_given_arg_cant_be_converted" do
    ['', 'glark', [], Object.new, :pat].each do |arg|
      assert_nil Regexp.try_convert(arg)
    end
  end

  # https://github.com/jruby/jruby/blob/master/test/externals/ruby1.9/uri/test_common.rb#L32
  it "test_jruby_uri_common_regexp" do
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
  it "test_jruby_quotes_string_arguments" do
    assert_equal /n|\./, Regexp.union("n", ".")
  end
end
