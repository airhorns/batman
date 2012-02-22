helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View yield, contentFor, and replace rendering'
  teardown: ->
    Batman.DOM._yieldContainers = {}
    Batman.DOM._yieldExecutors = {}

asyncTest 'it should insert content into yields when the content comes before the yield', 1, ->
  source = '''
  <div data-contentfor="baz">chunky bacon</div>
  <div data-yield="baz" id="test">erased</div>
  '''
  node = helpers.render source, {}, (node) ->
    equals node.children(0).html(), "chunky bacon"
    QUnit.start()

asyncTest 'it should insert content into yields when the content comes after the yield', 1, ->
  source = '''
  <div data-yield="baz" class="test">erased</div>
  <span data-contentfor="baz">chunky bacon</span>
  '''
  node = helpers.render source, {}, (node) ->
    equals node.children(0).html(), "chunky bacon"
    QUnit.start()

asyncTest 'bindings within yielded content should continue to update when the content comes before the yield', 2, ->
  source = '''
  <div data-contentfor="baz"><p data-bind="string"></p></div>
  <div data-yield="baz"></div>
  '''
  context = Batman string: "chunky bacon"
  helpers.render source, context, (node) ->
    equals node.find('p').html(), "chunky bacon"
    context.set 'string', 'why so serious'
    equals node.find('p').html(), "why so serious"
    QUnit.start()

asyncTest 'bindings within yielded content should continue to update when the content comes after the yield', 2, ->
  source = '''
  <div data-yield="baz"></div>
  <div data-contentfor="baz"><p data-bind="string"></p></div>
  '''
  context = Batman string: "chunky bacon"
  helpers.render source, context, (node) ->
    equals node.find('p').html(), "chunky bacon"
    context.set 'string', 'why so serious'
    equals node.find('p').html(), "why so serious"
    QUnit.start()

asyncTest 'bindings within nested yielded content should continue to update', 2, ->
  source = '''
  <div data-yield="baz">
    <div data-replace="baz">
      <p data-bind="string"></p>
    </div>
  </div>
  '''
  context = Batman string: "chunky bacon"
  helpers.render source, context, (node) ->
    equals node.find('p').html(), "chunky bacon"
    context.set 'string', 'why so serious'
    equals node.find('p').html(), "why so serious"
    QUnit.start()

asyncTest 'event handlers within yielded content should continue to fire when the content comes before the yield', 1, ->
  source = '''
  <div data-yield="baz"></div>
  <div data-contentfor="baz"><button data-event-click="handleClick"></p></div>
  '''
  context = Batman handleClick: spy = createSpy()
  helpers.render source, context, (node) ->
    helpers.triggerClick node.find('button')[0]
    ok spy.called
    QUnit.start()

asyncTest 'event handlers within yielded content should continue to fire when the content comes before the yield', 1, ->
  source = '''
  <div data-contentfor="baz"><button data-event-click="handleClick"></p></div>
  <div data-yield="baz"></div>
  '''
  context = Batman handleClick: spy = createSpy()
  helpers.render source, context, (node) ->
    helpers.triggerClick node.find('button')[0]
    ok spy.called
    QUnit.start()

asyncTest 'event handlers in nested yielded content should continue to fire', ->
  source = '''
    <div data-yield="foo">
      <div data-replace="foo">
        <button data-event-click="hmm"></button>
      </div>
    </div>
  '''

  context =
    hmm: spy = createSpy()

  helpers.render source, context, (node) ->
    helpers.triggerClick(node.find('button')[0])
    ok spy.called
    QUnit.start()

asyncTest 'it should yield multiple contentfors that render into the same yield', ->
  source = '''
  <div data-yield="mult" class="test"></div>
  <span data-contentfor="mult">chunky bacon</span>
  <span data-contentfor="mult">spicy sausage</span>
  '''
  node = helpers.render source, {}, (node) ->
    equals node.children(0).first().html(), "chunky bacon"
    equals node.children(0).first().next().html(), "spicy sausage"
    QUnit.start()

asyncTest 'it shouldn\'t go nuts if the content is already inside the yield', 1, ->
  source = '<div data-yield="baz" class="test">
              <span data-contentfor="baz">chunky bacon</span>
            </div>'
  node = helpers.render source, {}, (node) ->
    equals node.children(0).html(), "chunky bacon"
    QUnit.start()

asyncTest 'it should render content even if the yield doesn\'t exist yet', 1, ->
  helpers.render '<div data-contentfor="foo">immediate</div>', {}, (content) ->
    helpers.render '<div data-yield="foo"></div>', {}, (node) ->
      equal node.children(0).html(), 'immediate'
      QUnit.start()

asyncTest 'yielded content should animate when show/hide functions are mixed in', 6, ->
  showSpy = createSpy ->
  hideSpy = createSpy ->
  Batman.mixins.animation =
    show: showSpy
    hide: hideSpy
  helpers.render '<div data-yield="foo"></div><div data-contentfor="foo" data-mixin="animation">content</div>', {}, (node) ->
    equal showSpy.callCount, 1
    equal hideSpy.callCount, 0
    equal node.children(0).html(), 'content'

    helpers.render '<div data-replace="foo" data-mixin="animation">replaced</div>', {}, ->
      equal showSpy.callCount, 2
      equal hideSpy.callCount, 1
      equal node.children(0).html(), 'replaced'
      QUnit.start()

asyncTest 'data-replace should replace content without breaking contentfors', 2, ->
  source = '''
    <div data-yield="foo">start</div>
    <div data-replace="foo">replaces</div>
    <div data-contentfor="foo">appends</div>
  '''
  helpers.render source, {}, (node) ->
    equal node.children(0).first().html(), 'replaces'
    equal node.children(0).first().next().html(), 'appends'
    QUnit.start()

asyncTest 'data-replace should remove bindings on replaced content', ->
  source = '''
    <div data-yield="foo"></div>
    <div data-contentfor="foo"><span data-bind="expensive"></span></div>
    <div data-replace="foo"><input type="button" data-bind="simple"></input></div>
  '''
  context = new Batman.Object
    simple: 'simple'
  context.accessor 'expensive', spy = createSpy ->
    context.get 'simple'

  helpers.render source, context, (node) ->
    oldCallCount = spy.callCount
    context.set 'simple', 'updated'
    equal spy.callCount, oldCallCount
    QUnit.start()
