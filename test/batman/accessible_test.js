
  suite('Batman.Accessible', function() {
    test("new Batman.Accessible(accessor) just applies the constructor arguments to @accessor", function() {
      var fooAccessible, globallyAccessible;
      globallyAccessible = new Batman.Accessible(function() {
        return "some value";
      });
      assert.equal(globallyAccessible.get("some key"), "some value");
      fooAccessible = new Batman.Accessible("foo", function() {
        return "foo value";
      });
      assert.equal(fooAccessible.get("foo"), "foo value");
      return assert.equal(fooAccessible.get("bar"), void 0);
    });
    return test("new Batman.TerminalAccessible(accessor) applies any gets no matter how deep the keypath to the accessor", function() {
      var fooAccessible, globallyAccessible;
      globallyAccessible = new Batman.TerminalAccessible(function() {
        return "some value";
      });
      assert.equal(globallyAccessible.get("some.deep.key"), "some value");
      fooAccessible = new Batman.TerminalAccessible("foo", function() {
        return "foo value";
      });
      assert.equal(fooAccessible.get("foo"), "foo value");
      assert.equal(fooAccessible.get("foo.bar"), void 0);
      return assert.equal(fooAccessible.get("bar.baz"), void 0);
    });
  });
