helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View yield and contentFor rendering'

asyncTest 'it should insert content into yields when the content comes before the yield', 1, ->
  source = '''
  <div data-contentfor="baz">chunky bacon</div>
  <div data-yield="baz" id="test">erased</div>
  '''
  node = helpers.render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"

asyncTest 'it should insert content into yields when the content comes after the yield', 1, ->
  source = '''
  <div data-yield="baz" class="test">erased</div>
  <span data-contentfor="baz">chunky bacon</span>
  '''
  node = helpers.render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"

asyncTest 'it shouldn\'t go nuts if the content is already inside the yield', 1, ->
  source = '<div data-yield="baz" class="test">
              <span data-contentfor="baz">chunky bacon</span>
            </div>'
  node = helpers.render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"

QUnit.module 'Batman.View rendering with bindings'

asyncTest 'it should update simple bindings when they change', 2, ->
  context = Batman foo: 'bar'
  node = helpers.render '<div data-bind="foo"></div>', context, (node) ->
    equals node.html(), "bar"
    context.set('foo', 'baz')
    equals node.html(), "baz"
    QUnit.start()

asyncTest 'it should allow chained keypaths', 3, ->
  context = Batman
    foo: Batman
      bar: Batman
        baz: 'wallawalladingdong'

  helpers.render '<div data-bind="foo.bar.baz"></div>', context, (node) ->

    equals node.html(), "wallawalladingdong"
    context.set('foo.bar.baz', 'kablamo')
    equals node.html(), "kablamo"
    context.set('foo.bar', Batman baz: "whammy")
    equals node.html(), "whammy"

    QUnit.start()
