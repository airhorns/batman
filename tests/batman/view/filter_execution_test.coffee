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

asyncTest 'replace', 1, ->
  helpers.render '<div data-bind="foo | replace \'bar\', \'baz\'"></div>',
    foo: 'bar'
  , (node) ->
    equals node.html(), "baz"
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
  helpers.render '<input type="checkbox" data-bind="foo | not" />',
    foo: true
  , (node) ->
    equals node[0].checked, false
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

asyncTest 'map over a set', 1, ->
  helpers.render '<div data-bind="posts | map \'name\' | join \', \'"></div>',
    posts: new Batman.Set(
      Batman
        name: 'one'
        comments: 10
    , Batman
        name: 'two'
        comments: 20
    )
  , (node) ->
    equals node.html(), "one, two"
    QUnit.start()

asyncTest 'map over batman objects', 1, ->
  class Silly extends Batman.Object
    @accessor 'foo', -> 'bar'

  helpers.render '<div data-bind="posts | map \'foo\' | join \', \'"></div>',
    {posts: new Batman.Set(new Silly, new Silly)}
  , (node) ->
    equals node.html(), "bar, bar"
    QUnit.start()

asyncTest 'has in a set', 3, ->
  posts = new Batman.Set(
    Batman
      name: 'one'
      comments: 10
  , Batman
      name: 'two'
      comments: 20
  )

  context = Batman
    posts: posts
    post: posts.toArray()[0]

  helpers.render '<input type="checkbox" data-bind="posts | has post" />', context, (node) ->
    ok node[0].checked
    context.get('posts').remove(context.get('post'))
    delay ->
      ok !node[0].checked
      context.get('posts').add(context.get('post'))
      delay ->
        ok node[0].checked

asyncTest 'has in an array', 3, ->
  posts = [
    Batman
      name: 'one'
      comments: 10
  , Batman
      name: 'two'
      comments: 20
  ]

  secondPost = [posts[1]]

  context = Batman
    posts: posts
    post: posts[0]

  helpers.render '<input type="checkbox" data-bind="posts | has post" />', context, (node) ->
    ok node[0].checked
    context.set 'posts', secondPost
    delay ->
      ok !node[0].checked
      context.set 'posts', posts
      delay ->
        ok node[0].checked

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

QUnit.module "Batman.Filters: interpolate filter"

asyncTest "it should accept string literals", ->
  helpers.render '<div data-bind="\'this kind of defeats the purpose\' | interpolate"></div>', false, {}, (node) ->
    equal node.childNodes[0].innerHTML, "this kind of defeats the purpose"
    QUnit.start()

asyncTest "it should accept interpolation strings from other keypaths", ->
  helpers.render '<div data-bind="foo.bar | interpolate"></div>', false, {foo: {bar: "baz"}}, (node) ->
    equal node.childNodes[0].innerHTML, "baz"
    QUnit.start()

asyncTest "it should interpolate strings with simple values", ->
  source = '<div data-bind="\'pamplemouse %{kind}\' | interpolate {\'kind\': \'kind\'}"></div>'
  helpers.render source, false, {kind: 'vert'}, (node) ->
    equal node.childNodes[0].innerHTML, "pamplemouse vert"
    QUnit.start()

asyncTest "it should interpolate strings with undefined values", ->
  Batman.developer.suppress()
  source = '<div data-bind="\'pamplemouse %{kind}\' | interpolate {\'kind\': \'kind\'}"></div>'
  helpers.render source, false, {kind: undefined}, (node) ->
    Batman.developer.unsuppress()
    equal node.childNodes[0].innerHTML, "pamplemouse "
    QUnit.start()

asyncTest "it should interpolate strings with counts", ->
  context = Batman
    number: 1
    how_many_grapefruits:
      1: "1 pamplemouse"
      other: "%{count} pamplemouses"

  source = '<div data-bind="how_many_grapefruits | interpolate {\'count\': \'number\'}"></div>'
  helpers.render source, false, context, (node) ->
    equal node.childNodes[0].innerHTML, "1 pamplemouse"
    context.set 'number', 3
    helpers.render source, false, context, (node) ->
      equal node.childNodes[0].innerHTML, "3 pamplemouses"
      QUnit.start()


QUnit.module "Batman.View user defined filter execution"

asyncTest 'should render a user defined filter', 3, ->
  Batman.Filters['test'] = spy = createSpy().whichReturns("testValue")
  ctx = Batman
    foo: 'bar'
    bar: 'baz'
  helpers.render '<div data-bind="foo | test 1, \'baz\'"></div>', ctx, (node) ->
    equals node.html(), "testValue"
    equal Batman._functionName(spy.lastCallContext.constructor), 'RenderContext'
    deepEqual spy.lastCallArguments, ['bar', 1, 'baz']
    delete Batman.Filters.test
    QUnit.start()

