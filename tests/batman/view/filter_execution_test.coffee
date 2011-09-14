helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View filter execution'

asyncTest 'get', 1, ->
  context = Batman
    foo: new Batman.Hash({bar: "qux"})

  helpers.render '<div data-bind="foo | get \'bar\'"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get dotted syntax', 1, ->
  context = Batman
    foo: new Batman.Hash({bar: "qux"})

  helpers.render '<div data-bind="foo.bar"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get short syntax', 1, ->
  context = Batman
    foo: new Batman.Hash({bar: "qux"})

  helpers.render '<div data-bind="foo[\'bar\']"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get short syntax with looked-up key', 1, ->
  context = Batman
    key: 'bar'
    foo: new Batman.Hash({bar: "qux"})

  helpers.render '<div data-bind="foo[key]"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get short syntax with complex key', 1, ->
  context = Batman
    complex: { key: 'bar'}
    foo: new Batman.Hash({bar: "qux"})

  helpers.render '<div data-bind="foo[complex.key]"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get short syntax with chained dot lookup', 1, ->
  context = Batman
    key: 'bar'
    foo: new Batman.Hash({bar: { baz: "qux" }})

  helpers.render '<div data-bind="foo[key].baz"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'get chained short syntax', 1, ->
  context = Batman
    foo: new Batman.Hash({bar: {baz: "qux"}})

  helpers.render '<div data-bind="foo[\'bar\'][\'baz\']"></div>', context, (node) ->
    equals node.html(), "qux"
    QUnit.start()

asyncTest 'hideously complex chain of property lookups', 1, ->
  context = Batman
    ss: { ee: 'c' }
    a: new Batman.Hash
      b:
        c:
          d:
            e:
              f:
                g:
                  h: 'value'

  helpers.render '<div data-bind="a.b[ss.ee].d[\'e\'][\'f\'].g.h"></div>', context, (node) ->
    equals node.html(), "value"
    QUnit.start()

asyncTest 'hideously complex chain of property lookups with filters', 1, ->
  context = Batman
    ss: { ee: 'c' }
    a: new Batman.Hash
      b:
        c:
          d:
            e:
              f:
                g:
                  h: 'value'
  spyOn Batman.Filters, 'spy'
  helpers.render '<div data-bind="a.b[ss.ee].d[\'e\'][\'f\'].g.h | spy"></div>', context, (node) ->
    equal Batman.Filters.spy.lastCallArguments[0], 'value'
    delete Batman.Filters.spy
    QUnit.start()

asyncTest 'truncate', 2, ->
  helpers.render '<div data-bind="foo | truncate 5"></div>',
    foo: 'your mother was a hampster'
  , (node) ->
    equals node.html(), "yo..."

    helpers.render '<div data-bind="foo.bar | truncate 5, \'\'"></div>',
      foo: Batman
        bar: 'your mother was a hampster'
    , (node) ->
      equals node.html(), "your "
      QUnit.start()

asyncTest 'prepend', 1, ->
  helpers.render '<div data-bind="foo | prepend \'special-\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "special-bar"
    QUnit.start()

asyncTest 'append', 1, ->
  helpers.render '<div data-bind="foo | append \'-special\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "bar-special"
    QUnit.start()

asyncTest 'downcase', 1, ->
  helpers.render '<div data-bind="foo | downcase"></div>',
    foo: 'BAR'
  , (node) ->
    equals node.html(), "bar"
    QUnit.start()

asyncTest 'upcase', 1, ->
  helpers.render '<div data-bind="foo | upcase"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "BAR"
    QUnit.start()

asyncTest 'join', 2, ->
  helpers.render '<div data-bind="foo | join"></div>',
    foo: ['a', 'b', 'c']
  , (node) ->
    equals node.html(), "abc"

    helpers.render '<div data-bind="foo | join \'|\'"></div>',
      foo: ['a', 'b', 'c']
    , (node) ->
      equals node.html(), "a|b|c"
      QUnit.start()

asyncTest 'sort', 1, ->
  helpers.render '<div data-bind="foo | sort | join"></div>',
    foo: ['b', 'c', 'a', '1']
  , (node) ->
    equals node.html(), "1abc"
    QUnit.start()

asyncTest 'not', 1, ->
  helpers.render '<div data-showif="foo | not"></div>',
    foo: true
  , (node) ->
    equals node[0].style.display, "none"
    QUnit.start()


asyncTest 'map', 1, ->
  helpers.render '<div data-bind="posts | map \'name\' | join \', \'"></div>',
    posts: [
      Batman
        name: 'one'
        comments: 10
    , Batman
        name: 'two'
        comments: 20
    ]
  , (node) ->
    equals node.html(), "one, two"
    QUnit.start()

asyncTest 'map with a numeric key', 1, ->
  helpers.render '<div data-bind="counts | map 1 | join \', \'"></div>',
    counts: [
      [1, 2, 3]
      [4, 5, 6]
    ]
  , (node) ->
    equals node.html(), "2, 5"
    QUnit.start()

asyncTest 'map', 1, ->
  helpers.render '<div data-bind="posts | map \'name\' | join \', \'"></div>',
    posts: [
      Batman
        name: 'one'
        comments: 10
    , Batman
        name: 'two'
        comments: 20
    ]
  , (node) ->
    equals node.html(), "one, two"
    QUnit.start()

asyncTest 'meta', 2, ->
  context = Batman
    foo: Batman
      meta:
        get: spy = createSpy().whichReturns("something")

  helpers.render '<div data-bind="foo | meta \'bar\'"></div>', context, (node) ->
    equals node.html(), "something"
    deepEqual spy.lastCallArguments, ['bar']
    QUnit.start()

asyncTest 'meta binding to a hash', 2, ->
  context = Batman
    foo: new Batman.Hash(bar: "qux")

  helpers.render '<div data-bind="foo | meta \'length\'"></div>', context, (node) ->
    equals node.html(), "1"
    context.get('foo').set('corge', 'test')
    delay =>
      equals node.html(), "2"


QUnit.module "Batman.View filter value and parameter parsing"
  setup: ->
    Batman.Filters['test'] = @spy = createSpy().whichReturns("testValue")
  teardown: ->
    delete Batman.Filters.test

asyncTest "should parse one segment keypaths as values", ->
  helpers.render '<div data-bind="foo | test"></div>', Batman(foo: "bar"), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, ["bar"]
    QUnit.start()

asyncTest "should parse many segment keypaths as values", ->
  helpers.render '<div data-bind="foo.bar | test"></div>', Batman(foo: Batman(bar: "baz")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, ["baz"]
    QUnit.start()

asyncTest "should parse one segment keypaths as arguments", ->
  helpers.render '<div data-bind="1 | test foo"></div>', Batman(foo: "bar"), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "bar"]
    QUnit.start()

asyncTest "should parse one segment keypaths as arguments anywhere in the list of arguments", ->
  helpers.render '<div data-bind="1 | test foo, 2, bar, 3, baz"></div>', Batman(foo: "a", bar: "b", baz: "c"), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "a", 2, "b", 3, "c"]
    QUnit.start()

asyncTest "should parse one segment keypaths as arguments anywhere in the list of arguments", ->
  helpers.render '<div data-bind="1 | test qux.foo, 2, qux.bar, 3, qux.baz"></div>', Batman(qux: Batman(foo: "a", bar: "b", baz: "c")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "a", 2, "b", 3, "c"]
    QUnit.start()

asyncTest "should parse many segment keypaths as arguments", ->
  helpers.render '<div data-bind="1 | test foo.bar"></div>', Batman(foo: Batman(bar: "baz")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, "baz"]
    QUnit.start()

asyncTest "should parse keypaths containing true as arguments", ->
  helpers.render '<div data-bind="1 | test true.bar"></div>', Batman("true": Batman(bar: "baz")), (node) =>
    deepEqual @spy.lastCallArguments, [1, "baz"]

    helpers.render '<div data-bind="1 | test truesay.bar"></div>', Batman(truesay: Batman(bar: "baz")), (node) =>
      deepEqual @spy.lastCallArguments, [1, "baz"]
      QUnit.start()

asyncTest "should parse keypaths containing false as arguments", ->
  helpers.render '<div data-bind="1 | test false.bar"></div>', Batman("false": Batman(bar: "baz")), (node) =>
    deepEqual @spy.lastCallArguments, [1, "baz"]
    helpers.render '<div data-bind="1 | test falsified.bar"></div>', Batman(falsified: Batman(bar: "baz")), (node) =>
      deepEqual @spy.lastCallArguments, [1, "baz"]
      QUnit.start()

asyncTest "should not parse true or false as a keypath", ->
  helpers.render '<div data-bind="1 | test true"></div>', Batman("true": Batman(bar: "baz")), (node) =>
    equals node.html(), "testValue"
    deepEqual @spy.lastCallArguments, [1, true]
    helpers.render '<div data-bind="1 | test false"></div>', Batman(truesay: Batman(bar: "baz")), (node) =>
      equals node.html(), "testValue"
      deepEqual @spy.lastCallArguments, [1, false]
      QUnit.start()

QUnit.module "Batman.View user defined filter execution"

asyncTest 'should render a user defined filter', 3, ->
  Batman.Filters['test'] = spy = createSpy().whichReturns("testValue")
  ctx = Batman
    foo: 'bar'
    bar: 'baz'
  helpers.render '<div data-bind="foo | test 1, \'baz\'"></div>', ctx, (node) ->
    equals node.html(), "testValue"
    equals spy.lastCallContext, ctx
    deepEqual spy.lastCallArguments, ['bar', 1, 'baz']
    delete Batman.Filters.test
    QUnit.start()

