suite 'Batman', ->
  suite 'Navigator', ->
    test "normalizePath(segments...) joins the segments with slashes, prepends a slash if necessary, and removes final trailing slashes",  ->
      assert.equal Batman.Navigator.normalizePath(''), '/'
      assert.equal Batman.Navigator.normalizePath('','foo','','bar'), '/foo/bar'
      assert.equal Batman.Navigator.normalizePath('foo'), '/foo'
      assert.equal Batman.Navigator.normalizePath('/foo'), '/foo'
      assert.equal Batman.Navigator.normalizePath('//foo'), '//foo'
      assert.equal Batman.Navigator.normalizePath('foo','bar','baz'), '/foo/bar/baz'
      assert.equal Batman.Navigator.normalizePath('foo','//bar/baz/'), '/foo//bar/baz'
      assert.equal Batman.Navigator.normalizePath('foo','bar/baz//'), '/foo/bar/baz'
