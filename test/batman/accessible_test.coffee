suite 'Batman', ->
  suite 'Accessible', ->

    test "new Batman.Accessible(accessor) just applies the constructor arguments to @accessor", ->
      globallyAccessible = new Batman.Accessible -> "some value"
      assert.equal globallyAccessible.get("some key"), "some value"

      fooAccessible = new Batman.Accessible "foo", -> "foo value"
      assert.equal fooAccessible.get("foo"), "foo value"
      assert.equal fooAccessible.get("bar"), undefined

    test "new Batman.TerminalAccessible(accessor) applies any gets no matter how deep the keypath to the accessor", ->
      globallyAccessible = new Batman.TerminalAccessible -> "some value"
      assert.equal globallyAccessible.get("some.deep.key"), "some value"

      fooAccessible = new Batman.TerminalAccessible "foo", -> "foo value"
      assert.equal fooAccessible.get("foo"), "foo value"
      assert.equal fooAccessible.get("foo.bar"), undefined
      assert.equal fooAccessible.get("bar.baz"), undefined
