QUnit.module 'Batman.Accessible',
  setup: ->

test "new Batman.Accessible(accessor) just applies the constructor arguments to @accessor", ->
  globallyAccessible = new Batman.Accessible -> "some value"
  equal globallyAccessible.get("some key"), "some value"
  
  fooAccessible = new Batman.Accessible "foo", -> "foo value"
  equal fooAccessible.get("foo"), "foo value"
  equal fooAccessible.get("bar"), undefined