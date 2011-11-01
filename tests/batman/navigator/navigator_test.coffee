QUnit.module 'Batman.Navigator'
  setup: ->


test "normalizePath(segments...) joins the segments with slashes, prepends a slash if necessary, and removes final trailing slashes", ->
  equal Batman.Navigator.normalizePath(''), '/'
  equal Batman.Navigator.normalizePath('','foo','','bar'), '/foo/bar'
  equal Batman.Navigator.normalizePath('foo'), '/foo'
  equal Batman.Navigator.normalizePath('/foo'), '/foo'
  equal Batman.Navigator.normalizePath('//foo'), '//foo'
  equal Batman.Navigator.normalizePath('foo','bar','baz'), '/foo/bar/baz'
  equal Batman.Navigator.normalizePath('foo','//bar/baz/'), '/foo//bar/baz'
  equal Batman.Navigator.normalizePath('foo','bar/baz//'), '/foo/bar/baz'
