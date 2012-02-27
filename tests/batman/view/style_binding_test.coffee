helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View style bindings'

asyncTest 'data-bind-style should bind to a string', 4, ->
  source = '<input type="text" data-bind-style="string"></input>'
  context = Batman
    string: 'backgroundColor:blue; color:green;'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['backgroundColor'], 'blue'
    equal node.style['color'], 'green'

    context.set 'string', 'color: green'
    equal node.style['backgroundColor'], ''
    equal node.style['color'], 'green'

    QUnit.start()

asyncTest 'data-bind-style should bind to a vanilla object', 4, ->
  source = '<input type="text" data-bind-style="object"></input>'
  context = Batman
    object:
      'backgroundColor': 'blue'
      color: 'green'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['backgroundColor'], 'blue'
    equal node.style['color'], 'green'
    context.set 'object', {color: 'red'}
    equal node.style['backgroundColor'], ''
    equal node.style['color'], 'red'

    QUnit.start()

asyncTest 'data-bind-style should bind to a Batman object', 8, ->
  source = '<input type="text" data-bind-style="object"></input>'
  context = Batman
    object: new Batman.Hash
      'backgroundColor': 'blue'
      color: 'green'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['backgroundColor'], 'blue'
    equal node.style['color'], 'green'
    context.set 'object.color', 'blue'
    equal node.style['color'], 'blue'
    equal node.style['backgroundColor'], 'blue'
    context.unset 'object.color'
    equal node.style['color'], ''
    equal node.style['backgroundColor'], 'blue'
    context.set 'object', new Batman.Hash color: 'yellow'
    equal node.style['color'], 'yellow'
    equal node.style['backgroundColor'], 'blue'

    QUnit.start()

asyncTest 'data-bind-style should forget previously bound hashes', 6, ->
  source = '<div data-bind-style="hash"></div>'
  hash = new Batman.Hash
    'backgroundColor': 'blue'
    color: 'green'
  context = Batman hash: hash
  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['backgroundColor'], 'blue'
    equal node.style['color'], 'green'

    context.set 'hash', new Batman.Hash color: 'red'
    equal node.style['backgroundColor'], 'blue'
    equal node.style['color'], 'red'

    hash.set 'color', 'green'
    equal node.style['backgroundColor'], 'blue'
    equal node.style['color'], 'red'

    QUnit.start()

asyncTest 'data-bind-style should bind to a vanilla object of attr/keypath pairs', 4, ->
  source = '<input type="text" data-bind-style="styles"></input>'
  context = Batman
    color: 'blue'
    backgroundColor: 'green'
    styles:
      color: 'color'
      'backgroundColor': 'backgroundColor'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style.color, 'blue'
    equal node.style['backgroundColor'], 'green'
    context.set 'color', 'green'
    equal node.style.color, 'green'
    equal node.style['backgroundColor'], 'green'

    QUnit.start()

asyncTest 'data-bind-style should bind dash-separated CSS keys to camelized ones', 4, ->
  source = '<input type="text" data-bind-style="string"></input>'
  context = Batman
    string: 'background-color:blue; color:green;'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style['backgroundColor'], 'blue'
    equal node.style['color'], 'green'

    context.set 'string', 'color: green'
    equal node.style['backgroundColor'], ''
    equal node.style['color'], 'green'

    QUnit.start()

asyncTest 'data-bind-style should correctly work for style with absolute URL', 1, ->
  source = '<input type="text" data-bind-style="string"></input>'
  context = Batman
    string: 'background-image: url("http://batmanjs.org/images/logo.png");'

  helpers.render source, context, (node) ->
    node = node[0]
    equal node.style.backgroundImage.replace(/"/g,""), 'url(http://batmanjs.org/images/logo.png)'
    QUnit.start()
