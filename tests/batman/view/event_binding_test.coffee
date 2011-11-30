helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View event bindings'

asyncTest 'it should allow events to be bound and execute them in the context as specified on a multi key keypath', 2, ->
  context = Batman
    foo: Batman
      bar: Batman
        doSomething: (node, renderContext) ->
          equal @findKey('foo')[0], context.get('foo')
          equal renderContext.findKey('foo')[0], context.get('foo')
          QUnit.start()

  source = '<button data-event-click="foo.bar.doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])

asyncTest 'it should allow events to be bound and execute them in the context as specified on terminal keypath', 1, ->
  context = Batman
    doSomething: spy = createSpy()

  source = '<button data-event-click="doSomething"></button>'
  helpers.render source, context, (node) ->
    helpers.triggerClick(node[0])
    delay ->
      equal spy.lastCallContext, context

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

asyncTest 'it should allow event handlers to update', 2, ->
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

asyncTest 'it should allow change events on checkboxes to be bound', 1, ->
  context = new Batman.Object
    one: true
    doSomething: createSpy()

  helpers.render '<input type="checkbox" data-bind="one" data-event-change="doSomething"/>', context, (node) ->
    node[0].checked = false
    helpers.triggerChange(node[0])
    delay =>
      ok context.doSomething.called

asyncTest 'it should allow submit events on inputs to be bound', 2, ->
  context =
    doSomething: spy = createSpy()

  source = '<form><input data-event-submit="doSomething" /></form>'
  helpers.render source, context, (node) ->
    helpers.triggerKey(node[0].childNodes[0], 13)
    delay ->
      ok spy.called
      equal spy.lastCallArguments[0], node[0].childNodes[0]

asyncTest 'it should allow form submit events to be bound', 1, ->
  context =
    doSomething: spy = createSpy()

  source = '<form data-event-submit="doSomething"><input type="submit" id="submit" /></form>'
  helpers.render source, context, (node) ->
    helpers.triggerSubmit(node[0])
    delay =>
      ok spy.called

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


