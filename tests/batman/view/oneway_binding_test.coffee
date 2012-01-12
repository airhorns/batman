helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View: one-way bindings'

asyncTest 'target should update only the javascript value', 3, ->
  source = '<input type="text" data-target="foo" value="start"/>'
  context = Batman foo: null
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.value, 'start'
    node.value = 'bar'
    helpers.triggerChange node
    delay =>
      equal context.get('foo'), 'bar'
      context.set 'foo', 'baz'
      delay =>
        equal node.value, 'bar'

asyncTest 'target should get the value from the node upon binding', 1, ->
  source = '<input type="text" data-target="foo" value="start"/>'
  context = Batman foo: null
  helpers.render source, context, (node) ->
    node = node[0]
    equal context.get('foo'), 'start'
    QUnit.start()

asyncTest 'source should update only the bound node', 3, ->
  source = '<input type="text" data-source="foo" value="start"/>'
  context = Batman foo: 'bar'
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.value, 'bar'
    node.value = 'baz'
    helpers.triggerChange node
    delay =>
      equal context.get('foo'), 'bar'
      context.set 'foo', 'end'
      delay =>
        equal node.value, 'end'

asyncTest 'attribute source should update only the bound attribute on the node', 3, ->
  source = '<input type="text" data-source-width="foo.width" value="start" width="10"/>'
  context = Batman
    foo: Batman
      width: 20
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.getAttribute('width'), '20'
    node.setAttribute 'width', 30
    helpers.triggerChange node
    delay =>
      equal context.get('foo.width'), 20 # nodeChange has no effect
      context.set 'foo.width', 40
      delay =>
        equal node.getAttribute('width'), '40'

asyncTest 'data-source and data-target work correctly on the same node', ->
  source = '<input type="text" data-target="there" data-source="here" value="start"/>'
  context = Batman here: 'here', there: ''
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.value, 'here'
    equal context.get('there'), 'here'
    node.value = 'there'
    helpers.triggerChange node
    delay =>
      equal context.get('there'), 'there'
      equal context.get('here'), 'here'


