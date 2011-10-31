QUnit.module 'Batman.Navigation'
  setup: ->


test "normalizePath(segments...) joins the segments with slashes, prepends a slash if necessary, and removes final trailing slashes", ->
  equal Batman.Navigation.normalizePath(''), '/'
  equal Batman.Navigation.normalizePath('','foo','','bar'), '/foo/bar'
  equal Batman.Navigation.normalizePath('foo'), '/foo'
  equal Batman.Navigation.normalizePath('/foo'), '/foo'
  equal Batman.Navigation.normalizePath('//foo'), '//foo'
  equal Batman.Navigation.normalizePath('foo','bar','baz'), '/foo/bar/baz'
  equal Batman.Navigation.normalizePath('foo','//bar/baz/'), '/foo//bar/baz'
  equal Batman.Navigation.normalizePath('foo','bar/baz//'), '/foo/bar/baz'
