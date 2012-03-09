helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View event bindings'

asyncTest 'it should allow events to be bound and execute them in the context as specified on a multi key keypath', 3, ->
  context = Batman
    foo: Batman
      bar: Batman
        doSomething: spy = createSpy()

  source = '<button data-event-click="foo.bar.doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      equal spy.lastCallContext, context.get('foo.bar')
      equal spy.lastCallArguments[0], node[0]
      equal spy.lastCallArguments[2].findKey('foo')[0], context.get('foo')

asyncTest 'it should allow events to be bound and execute them in the context as specified on terminal keypath', 3, ->
  context = Batman
    foo: 'bar'
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      equal spy.lastCallContext, context
      equal spy.lastCallArguments[0], node[0]
      equal spy.lastCallArguments[2].get('foo'), 'bar'

asyncTest 'it should allow click events to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]

asyncTest 'it should allow double click events to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<button data-event-doubleclick="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerDoubleClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]

asyncTest 'it should allow un-special-cased events like focus to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<input type="text" data-event-focus="doSomething" value="foo"></input>'
  helpers.render source, context, (node) ->
    helpers.triggerFocus(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]

asyncTest 'it should allow event handlers to update', 3, ->
  context = Batman
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called
      context.set('doSomething', newSpy = createSpy())
      helpers.triggerClick(node[0])
      delay ->
        ok newSpy.called
        equal spy.callCount, 1

asyncTest 'it should allow change events on checkboxes to be bound', 2, ->
  context = new Batman.Object
    one: true
    doSomething: createSpy()

  helpers.render '<input type="checkbox" data-bind="one" data-event-change="doSomething"/>', context, (node) ->
    node[0].checked = false
    helpers.triggerChange(node[0])
    delay =>
      ok context.doSomething.called
      ok context.doSomething.lastCallArguments[2].findKey

asyncTest 'it should allow submit events on inputs to be bound', 3, ->
  context =
    doSomething: spy = createSpy()

  source = '<form><input data-event-submit="doSomething" /></form>'
  helpers.render source, context, (node) ->
    helpers.triggerKey(node[0].childNodes[0], 13)
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0].childNodes[0]
      ok spy.lastCallArguments[2].findKey

asyncTest 'it should ignore keyup events with no associated keydown events', 2, ->
  # This can happen when we move the focus between nodes while handling some of these events.
  context =
    doSomething: aSpy = createSpy()
    doAnother: anotherSpy = createSpy()

  source = '<form><input data-event-submit="doSomething" /><input data-event-submit="doAnother"></form>'
  helpers.render source, context, (node) ->
    helpers.triggerKey(node[0].childNodes[1], 13, ["keydown", "keypress"])
    helpers.triggerKey(node[0].childNodes[0], 13, ["keyup"])
    delay ->
      ok !aSpy.called
      ok !anotherSpy.called

asyncTest 'it should allow form submit events to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<form data-event-submit="doSomething"><input type="submit" id="submit" /></form>'
  helpers.render source, context, (node) ->
    helpers.triggerSubmit(node[0])
    delay =>
      ok spy.called
      ok spy.lastCallArguments[2].findKey

asyncTest 'allows data-event-click attributes to reference native model properties directly', ->
  spy = createSpy()
  class Foo extends Batman.Model
    handleClick: spy

  source = '<button data-event-click="foo.handleClick"></button>'

  helpers.render source, {foo: new Foo()}, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0]

asyncTest 'should pass the context to other events without special handlers', 3, ->
  context =
    doSomething: spy = createSpy()

  source = '<form><input data-event-keypress="doSomething" /></form>'
  helpers.render source, context, (node) ->
    helpers.triggerKey(node[0].childNodes[0], 65)
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0].childNodes[0]
      ok spy.lastCallArguments[2].findKey

