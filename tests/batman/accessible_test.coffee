QUnit.module 'Batman.Accessible'

test "new Batman.Accessible(accessor) just applies the constructor arguments to @accessor", ->
  globallyAccessible = new Batman.Accessible -> "some value"
  equal globallyAccessible.get("some key"), "some value"

  fooAccessible = new Batman.Accessible "foo", -> "foo value"
  equal fooAccessible.get("foo"), "foo value"
  equal fooAccessible.get("bar"), undefined

test "new Batman.TerminalAccessible(accessor) applies any gets no matter how deep the keypath to the accessor", ->
  globallyAccessible = new Batman.TerminalAccessible -> "some value"
  equal globallyAccessible.get("some.deep.key"), "some value"

  fooAccessible = new Batman.TerminalAccessible "foo", -> "foo value"
  equal fooAccessible.get("foo"), "foo value"
  equal fooAccessible.get("foo.bar"), undefined
  equal fooAccessible.get("bar.baz"), undefined
