class TestEnumerator
  Batman.mixin @::, Batman.Enumerable
  constructor: (args...) ->
    @a = []
    @a.push arg for arg in args
  add: (e) -> @a.push e
  forEach: (f) ->
    @a.forEach(f)

getEnumerable = (array) -> new TestEnumerator(array...)

suite "Batman", ->
  suite "Enumerable mixin", ->

    test "classes mixing in enumerable should report as such", ->
      class Test
        Batman.mixin @::, Batman.Enumerable

      assert.ok (new Test).isEnumerable

    test "map should return an array of the results", ->
      @array = [1,2,3]
      @enumerable = getEnumerable(@array)
      f = (x) -> x * 10
      assert.deepEqual @enumerable.map(f), @array.map(f)

    test "every should test every element", ->
      @array = [true, true, true]
      @enumerable = getEnumerable(@array)
      f = (x) -> !!x
      assert.deepEqual @enumerable.every(f), @array.every(f)

      @array = [false, true, true]
      @enumerable = getEnumerable(@array)
      assert.deepEqual @enumerable.every(f), @array.every(f)

    test "some should test every element", ->
      @array = [false, false, false]
      @enumerable = getEnumerable(@array)
      f = (x) -> !!x
      assert.deepEqual @enumerable.some(f), @array.some(f)

      @array = [true, false, true]
      @enumerable = getEnumerable(@array)
      assert.deepEqual @enumerable.some(f), @array.some(f)

    suite 'filter', ->
      test "filter should return an instance of the constructor if the constructor has `add` or `push` defined", ->
        @array = [false, false, false]
        @enumerable = getEnumerable(@array)
        f = (x) -> !!x
        filtered = @enumerable.filter(f)
        assert.ok filtered instanceof TestEnumerator
        assert.deepEqual filtered.a, @array.filter(f)

        class SillyEnumerable extends TestEnumerator
          add: null
          push: (a) ->
            @a.push a

        @enumerable = new SillyEnumerable(@array...)
        filtered = @enumerable.filter(f)
        assert.ok filtered instanceof SillyEnumerable
        assert.deepEqual filtered.a, @array.filter(f)

      test "filter should return an instance of the constructor if the constructor has `set` defined built with k,v pairs", ->
        @array = [false, false, false]
        class SillyEnumerable
          Batman.mixin @::, Batman.Enumerable
          constructor: (args...) ->
            @a = {}
            Batman.mixin @a, args...
          forEach: (f) ->
            for k, v of @a
              f(k, v)
          set: (k, v) ->
            @a[k] = v
        f = (k) -> k == 'a'
        filtered = new SillyEnumerable({a: "1", b: "2"}).filter(f)
        assert.ok filtered instanceof SillyEnumerable
        assert.deepEqual filtered, new SillyEnumerable({a: "1"})

      test "filter should return an array if the constructor doesn't have add, set, or push defined", ->
        class SillyEnumerable
          Batman.mixin @::, Batman.Enumerable
          constructor: (args...) ->
            @a = []
            @a.push arg for arg in args
          forEach: (f) ->
            @a.forEach(f)

        @array = [false, false, false]
        @enumerable = new SillyEnumerable(@array...)
        f = (x) -> !!x
        assert.deepEqual @enumerable.filter(f), @array.filter(f)

        @array = [{}, false, true]
        @enumerable = new SillyEnumerable(@array...)
        assert.deepEqual @enumerable.filter(f), @array.filter(f)

    suite 'reduce', ->
      test "reduce should use the first value as the start value if no initial value is given", ->
        @array = [o1 = {}, true, true]
        @enumerable = getEnumerable(@array)
        first = true
        f = (x, acc) ->
          if first
            assert.equal x, o1
            first = false
          true

        assert.deepEqual @enumerable.reduce(f), @array.reduce(f)

      test "reduce should use the passed in initial value if given", ->
        @array = [o1 = {}, true, true]
        @enumerable = getEnumerable(@array)
        initial = {}
        first = true
        f = (x, acc) ->
          if first
            assert.equal x, initial
            first = false
          true

        assert.deepEqual @enumerable.reduce(f, initial), @array.reduce(f, initial)

      test "reduce should return a value", ->
        @array = [1, 2, 3]
        @enumerable = getEnumerable(@array)
        f = (x, acc) -> acc + x
        assert.deepEqual @enumerable.reduce(f), @array.reduce(f)
