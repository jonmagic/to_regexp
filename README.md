# to_regexp

Basically a safe way to convert strings to regexps (with options).

```ruby
str = "/finalis(é)/im"
old_way = eval(str)     # not safe
new_way = str.to_regexp # provided by this gem
old_way == new_way      # true
```

You can also treat strings as literal regexps. These two are equivalent:

```ruby
'/foo/'.to_regexp                                       #=> /foo/
'foo'.to_regexp(:literal => true)                       #=> /foo/
```

If you need case insensitivity and you're using <tt>:literal</tt>, pass options like <tt>:ignore_case</tt>. These two are equivalent:

```ruby
'/foo/i'.to_regexp                                      #=> /foo/i
'foo'.to_regexp(:literal => true, :ignore_case => true) #=> /foo/i
```

You can get the options passed to <tt>Regexp.new</tt> with <tt>#as_regexp</tt>:

```ruby
'/foo/'.to_regexp == Regexp.new('/foo/'.as_regexp) # true
```

Finally, you can be more lazy using <tt>:detect</tt>:

```ruby
'foo'.to_regexp(detect: true)     #=> /foo/
'foo\b'.to_regexp(detect: true)   #=> %r{foo\\b}
'/foo\b/'.to_regexp(detect: true) #=> %r{foo\b}
'foo\b/'.to_regexp(detect: true)  #=> %r{foo\\b/}
```

## Contributors
- [@seamusabshere](https://github.com/seamusabshere)
- [@jonmagic](https://github.com/jonmagic)

Copyright 2012 Seamus Abshere
