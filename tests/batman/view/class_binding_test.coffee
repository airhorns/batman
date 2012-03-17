helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View class bindings'

asyncTest 'it should allow a class to be bound', 6, ->
  source = '<div data-addclass-one="foo" data-removeclass-two="bar" class="zero"></div>'
  helpers.render source,
    foo: true
    bar: true
  , (node) ->
    ok node.hasClass('zero')
    ok node.hasClass('one')
    ok !node.hasClass('two')

    helpers.render source,
      foo: false
      bar: false
    , (node) ->
      ok node.hasClass('zero')
      ok !node.hasClass('one')
      ok node.hasClass('two')
      QUnit.start()

asyncTest 'it should allow a multiple similiar class names to be bound', 7, ->
  source = '<div data-addclass-answered="foo" data-addclass-reanswered="bar" class="unanswered"></div>'
  helpers.render source,
    foo: true
    bar: true
  , (node) ->
    ok node.hasClass('unanswered')
    ok node.hasClass('answered')
    ok node.hasClass('reanswered')

    helpers.render source,
      foo: false
      bar: true
    , (node) ->
      ok node.hasClass('unanswered')
      ok node.hasClass('reanswered')
      ok !node.hasClass('answered')
      ok !node.hasClass('un')
      QUnit.start()

asyncTest 'it should allow multiple class names to be bound and updated', ->
  source = '<div data-bind-class="classes"></div>'
  context = Batman classes: 'foo bar'
  helpers.render source, context, (node) ->
    equal node[0].className, 'foo bar'
    context.set 'classes', 'bar baz'
    delay =>
      equal node[0].className, 'bar baz'


asyncTest 'it should allow an already present class to be removed', 6, ->
  source = '<div data-removeclass-two="bar" class="zero two three"></div>'
  context = Batman
    foo: true
    bar: false
  helpers.render source, context, (node) ->
    ok node.hasClass('zero')
    ok node.hasClass('two')
    ok node.hasClass('three')

    context.set 'bar', true
    delay ->
      ok node.hasClass('zero')
      ok !node.hasClass('two')
      ok node.hasClass('three')

asyncTest 'it should not remove an already present similar class name', 6, ->
  source = '<div data-removeclass-foobar="bar" class="zero bar"></div>'
  context = Batman
    foo: true
    bar: false
  helpers.render source, context, (node) ->
    ok node.hasClass('zero')
    ok node.hasClass('bar')
    ok node.hasClass('foobar')

    context.set 'bar', true
    delay ->
      ok node.hasClass('zero')
      ok node.hasClass('bar')
      ok !node.hasClass('foobar')

asyncTest 'it should allow multiple class names to be bound and updated via set', ->
  source = '<div data-bind-class="classes"></div>'
  context = Batman
    classes: new Batman.Set('foo', 'bar', 'baz')

  helpers.render source, context, (node) ->
    ok node.hasClass('foo')
    ok node.hasClass('bar')
    ok node.hasClass('baz')
    context.get('classes').remove('foo')
    delay =>
      ok !node.hasClass('foo')
      ok node.hasClass('bar')
      ok node.hasClass('baz')

asyncTest 'it should allow multiple class names to be bound and updated via hash', ->
  source = '<div data-bind-class="classes"></div>'
  context = Batman
    classes: new Batman.Hash
      foo: true
      bar: true
      baz: true

  helpers.render source, context, (node) ->
    equal node[0].className, 'foo bar baz'
    context.get('classes').unset('foo')
    delay =>
      equal node[0].className, 'bar baz'

asyncTest 'it should allow multiple class names to be bound via object', ->
  source = '<div data-bind-class="classes"></div>'
  context = Batman
    classes:
      foo: true
      bar: true
      baz: true

  helpers.render source, context, (node) ->
    equal node[0].className, 'foo bar baz'
    context.set('classes', {bar: true, baz: true})
    delay =>
      equal node[0].className, 'bar baz'
