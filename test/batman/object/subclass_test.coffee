suite "Batman", ->
  suite "Object", ->
    suite "sub-classes and sub-sub-classes", ->
      subClass = false
      subSubClass = false

      setup ->
        class subClass extends Batman.Object
        class subSubClass extends subClass

      test "subclasses should have the dsl helpers defined",  ->
        assert.ok subClass.property
        assert.ok subSubClass.property

      test "instances should have observable mixed in",  ->
        assert.ok (new subClass).get
        assert.ok (new subSubClass).get
        assert.ok (new subClass).set
        assert.ok (new subSubClass).set

      test "instances shouldn't share attributes",  ->
        obj = new subClass
        obj2 = new subClass
        obj3 = new subSubClass
        obj4 = new subSubClass

        obj.set("foo", "bar")
        for o in [obj2, obj3, obj4]
          assert.equal o.get('foo'), undefined

        obj4.set("baz", "qux")
        for o in [obj, obj2, obj3]
          assert.equal o.get('baz'), undefined

      test "classes should have observable mixed in",  ->
        assert.ok  subClass.get
        assert.ok  subSubClass.get
        assert.ok  subClass.set
        assert.ok  subSubClass.set

      test "classes shouldn't share attributes",  ->
        subSubClass.set("foo", "bar")
        assert.equal subSubClass.get("foo"), "bar"
        assert.equal subClass.get("foo"), undefined

      test "classes should share observables",  ->
        subClass.observe 'foo', spy = createSpy()
        subSubClass.observe 'foo', subSpy = createSpy()
        subSubClass.set 'foo', 'bar'

        assert.equal spy.callCount, 1
        assert.equal subSpy.callCount, 1

        subClass.set 'foo', 'bar'
        assert.equal spy.callCount, 2
        assert.equal subSpy.callCount, 1

      test "newly created classes should fire observers on parent classes",  ->
        subClass.observe 'foo', spy = createSpy()

        newSubClass = class TestSubClass extends subClass
        newSubClass.observe 'foo', subSpy = createSpy()
        newSubClass.set 'foo', 'bar'
        assert.ok spy.called
        assert.ok subSpy.called

      test "parent classes shouldn't fire observers on newly created classes",  ->
        subClass.observe 'foo', spy = createSpy()

        newSubClass = class TestSubClass extends subClass
        newSubClass.observe 'foo', subSpy = createSpy()

        subClass.set 'foo', 'bar'
        assert.ok spy.called
        assert.ok !subSpy.called

      test "it should allow observation via the class",  ->
        a = createSpy()
        class Custom extends Batman.Object
          @observeAll 'foo', a

        obj = new Custom
        obj2 = new Custom

        obj.set("foo", "baz")
        assert.equal a.callCount, 1
        obj2.set("foo", "qux")
        assert.equal a.callCount, 2
