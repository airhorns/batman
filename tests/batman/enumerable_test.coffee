class TestEnumerator
  Batman.mixin @::, Batman.Enumerable
  constructor: (args...) ->
    @a = []
    @a.push arg for arg in args
  add: (e) -> @a.push e
  forEach: (f) ->
    @a.forEach(f)

getEnumerable = (array) -> new TestEnumerator(array...)
QUnit.module "Batman.Enumerable mixin"

test "classes mixing in enumerable should report as such", ->
  class Test
    Batman.mixin @::, Batman.Enumerable

  ok (new Test).isEnumerable

test "map should return an array of the results", ->
  @array = [1,2,3]
  @enumerable = getEnumerable(@array)
  f = (x) -> x * 10
  deepEqual @enumerable.map(f), @array.map(f)

test "mapToProperty should return an array of properties", ->
  array = [Batman(a:1), Batman(a:'2'), Batman(foo:null), Batman(a:null)]
  enumerable = getEnumerable(array)
  deepEqual enumerable.mapToProperty('a'), [1, '2', undefined, null]

test "every should test every element", ->
  @array = [true, true, true]
  @enumerable = getEnumerable(@array)
  f = (x) -> !!x
  deepEqual @enumerable.every(f), @array.every(f)

  @array = [false, true, true]
  @enumerable = getEnumerable(@array)
  deepEqual @enumerable.every(f), @array.every(f)

test "some should test every element", ->
  @array = [false, false, false]
  @enumerable = getEnumerable(@array)
  f = (x) -> !!x
  deepEqual @enumerable.some(f), @array.some(f)

  @array = [true, false, true]
  @enumerable = getEnumerable(@array)
  deepEqual @enumerable.some(f), @array.some(f)

test "filter should return an instance of the constructor if the constructor has `add` or `push` defined", ->
  @array = [false, false, false]
  @enumerable = getEnumerable(@array)
  f = (x) -> !!x
  filtered = @enumerable.filter(f)
  ok filtered instanceof TestEnumerator
  deepEqual filtered.a, @array.filter(f)

  class SillyEnumerable extends TestEnumerator
    add: null
    push: (a) ->
      @a.push a

  @enumerable = new SillyEnumerable(@array...)
  filtered = @enumerable.filter(f)
  ok filtered instanceof SillyEnumerable
  deepEqual filtered.a, @array.filter(f)

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
  ok filtered instanceof SillyEnumerable
  deepEqual filtered, new SillyEnumerable({a: "1"})

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
  deepEqual @enumerable.filter(f), @array.filter(f)

  @array = [{}, false, true]
  @enumerable = new SillyEnumerable(@array...)
  deepEqual @enumerable.filter(f), @array.filter(f)

test "reduce should use the first value as the start value if no initial value is given", ->
  @array = [o1 = {}, true, true]
  @enumerable = getEnumerable(@array)
  first = true
  f = (x, acc) ->
    if first
      equal x, o1
      first = false
    true

  deepEqual @enumerable.reduce(f), @array.reduce(f)

test "reduce should use the passed in initial value if given", ->
  @array = [o1 = {}, true, true]
  @enumerable = getEnumerable(@array)
  initial = {}
  first = true
  f = (x, acc) ->
    if first
      equal x, initial
      first = false
    true

  deepEqual @enumerable.reduce(f, initial), @array.reduce(f, initial)

test "reduce should return a value", ->
  @array = [1, 2, 3]
  @enumerable = getEnumerable(@array)
  f = (x, acc) -> acc + x
  deepEqual @enumerable.reduce(f), @array.reduce(f)
