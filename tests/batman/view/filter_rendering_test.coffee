helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View filter rendering'

asyncTest 'should render filters at one key deep keypaths', 1, ->
  node = helpers.render '<div data-bind="foo | upcase"></div>',
    foo: 'foo'
  , (node) ->
    equals node.html(), "FOO"
    QUnit.start()

asyncTest 'should render filters at n deep keypaths', 2, ->
  helpers.render '<div data-bind="foo.bar | upcase"></div>',
    foo: Batman
      bar: 'baz'
  , (node) ->
    equals node.html(), "BAZ"
    helpers.render '<div data-bind="foo.bar.baz | upcase "></div>',
      foo: Batman
        bar: Batman
          baz: "qux"
    , (node) ->
      equals node.html(), "QUX"
      QUnit.start()

asyncTest 'should render chained filters', 1, ->
  node = helpers.render '<div data-bind="foo | upcase | downcase"></div>',
    foo: 'foo'
  , (node) ->
    equals node.html(), "foo"
    QUnit.start()

asyncTest 'should update bindings with the filtered value if they change', 1, ->
  context = Batman
    foo: 'bar'
  helpers.render '<div data-bind="foo | upcase"></div>', context, (node) ->
    context.set('foo', 'baz')
    equals node.html(), 'BAZ'
    QUnit.start()

asyncTest 'should allow filtering on attributes', 2, ->
  helpers.render '<div data-addclass-works="bar | first" data-bind-attr="foo | upcase "></div>',
    foo: "bar"
    bar: [true]
  , (node) ->
    ok node.hasClass('works')
    equals node.attr('attr'), 'BAR'
    QUnit.start()

asyncTest 'should allow filtering on simple values', 1, ->
  helpers.render '<div data-bind="\'foo\' | upcase"></div>', {}, (node) ->
    equals node.html(), 'FOO'
    QUnit.start()

asyncTest 'should allow filtering on objects and arrays', 2, ->
  helpers.render '<div data-bind="[1,2,3] | join \' \'"></div>', {}, (node) ->
    equals node.html(), '1 2 3'

    Batman.Filters.dummyObjectFilter = (value, key) -> value[key]
    helpers.render '<div data-bind="{\'foo\': \'bar\', \'baz\': 4} | dummyObjectFilter \'foo\'"></div>', {}, (node) ->
      equals node.html(), 'bar'
      QUnit.start()

asyncTest 'should allow keypaths as arguments to filters', 1, ->
  helpers.render '<div data-bind="foo | join bar"></div>',
    foo: [1,2,3]
    bar: ':'
  , (node) ->
    equals node.html(), '1:2:3'
    QUnit.start()

asyncTest 'should update bindings when argument keypaths change', 1, ->
  context = Batman
    foo: [1,2,3]
    bar: ''

  helpers.render '<div data-bind="foo | join bar"></div>', context, (node) ->
    context.set('bar', "-")
    delay ->
      equals node.html(), '1-2-3'

asyncTest 'should allow filtered keypaths as arguments to context', 1, ->
  context = Batman
    foo: Batman
      baz: Batman
        qux: "filtered!"
    bar: 'baz'

  helpers.render '<div data-context-corge="foo | get bar"><div id="test" data-bind="corge.qux"></div></div>', context, (node) ->
    delay ->
      equals $("#test", node).html(), 'filtered!'

asyncTest 'should allow filtered keypaths as arguments to formfor', 1, ->
  class SingletonDooDad extends Batman.Object
    someKey: 'foobar'

    @classAccessor 'instance',
      get: (key) ->
        unless @_instance
          @_instance = new SingletonDooDad
        @_instance

  context = Batman
    klass: SingletonDooDad

  source = '<form data-formfor-obj="klass | get \'instance\'"><span id="test" data-bind="obj.someKey"></span></form>'
  helpers.render source, context, (node) ->
    delay ->
      equals $("#test", node).html(), 'foobar'

asyncTest 'should allow filtered keypaths as arguments to mixin', 1, ->
  context = Batman
    foo: Batman
      baz:
        someKey: "foobar"
    bar: 'baz'

  helpers.render '<div id="test" data-mixin="foo | get bar"></div>', context, (node) ->
    delay ->
      equals node[0].someKey, 'foobar'

asyncTest 'should allow filtered keypaths as arguments to foreach', 3, ->
  context = Batman
    foo: Batman
      baz: [Batman(key: 1), Batman(key: 2), Batman(key: 3)]
    bar: 'baz'

  helpers.render '<div><span class="tracking" data-foreach-number="foo | get bar" data-bind="number.key"></span></div>', context, (node) ->
    delay ->
      tracker = {'1': false, '2': false, '3': false}
      $(".tracking", node).each (i, x) ->
        tracker[$(x).html()] = true
      ok tracker['1']
      ok tracker['2']
      ok tracker['3']


