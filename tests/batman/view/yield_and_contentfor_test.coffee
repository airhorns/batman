helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View yield, contentFor, and replace rendering'

asyncTest 'it should insert content into yields when the content comes before the yield', 1, ->
  source = '''
  <div data-contentfor="baz">chunky bacon</div>
  <div data-yield="baz" id="test">erased</div>
  '''
  node = helpers.render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"

asyncTest 'it should insert content into yields when the content comes after the yield', 2, ->
  source = '''
  <div data-yield="baz" class="test">erased</div>
  <span data-contentfor="baz">chunky bacon</span>
  '''
  node = helpers.render source, {}, (node) ->
    delay =>
      equals node.children(0).html(), "chunky bacon"
      equal Batman.DOM._yielders["baz"], undefined, "_yielders was cleared"

asyncTest 'it should yield multiple contentfors that render into the same yield', ->
  source = '''
  <div data-yield="mult" class="test"></div>
  <span data-contentfor="mult">chunky bacon</span>
  <span data-contentfor="mult">spicy sausage</span>
  '''
  node = helpers.render source, {}, (node) ->
    delay =>
      equals node.children(0).first().html(), "chunky bacon"
      equals node.children(0).first().next().html(), "spicy sausage"

asyncTest 'it shouldn\'t go nuts if the content is already inside the yield', 1, ->
  source = '<div data-yield="baz" class="test">
              <span data-contentfor="baz">chunky bacon</span>
            </div>'
  node = helpers.render source, {}, (node) ->
    delay ->
      equals node.children(0).html(), "chunky bacon"

asyncTest 'it should render content even if the yield doesn\'t exist yet', 1, ->
  helpers.render '<div data-contentfor="foo">immediate</div>', {}, (content) ->
    helpers.render '<div data-yield="foo"></div>', {}, (node) ->
      delay =>
        equal node.children(0).html(), 'immediate'

asyncTest 'yielded content should animate when show/hide functions are mixed in', 6, ->
  showSpy = createSpy ->
  hideSpy = createSpy ->
  Batman.mixins.animation =
    show: showSpy
    hide: hideSpy
  helpers.render '<div data-yield="foo"></div><div data-contentfor="foo" data-mixin="animation">content</div>', {}, (node) ->
    setTimeout (->
      equal showSpy.callCount, 1
      equal hideSpy.callCount, 0
      equal node.children(0).html(), 'content'

      helpers.render '<div data-replace="foo" data-mixin="animation">replaced</div>', {}, ->
        delay =>
          equal showSpy.callCount, 2
          equal hideSpy.callCount, 1
          equal node.children(0).html(), 'replaced'
    ), 50

asyncTest 'data-replace should replace content without breaking contentfors', 2, ->
  source = '''
    <div data-yield="foo">start</div>
    <div data-replace="foo">replaces</div>
    <div data-contentfor="foo">appends</div>
  '''
  helpers.render source, {}, (node) ->
    delay =>
      equal node.children(0).first().html(), 'replaces'
      equal node.children(0).first().next().html(), 'appends'

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
    delay =>
      oldCallCount = spy.callCount
      context.set 'simple', 'updated'
      delay =>
        equal spy.callCount, oldCallCount

asyncTest 'should propogate event handlers in nested yielded content', ->
  source = '''
    <div data-yield="foo"></div>
    <div data-replace="foo">
      <form data-replace="foo">
        <button data-event-click="hmm"></button>
      </form>
    </div>
  '''

  context =
    hmm: spy = createSpy()

  helpers.render source, context, (node) ->
    delay =>
      helpers.triggerClick(node[0].childNodes[0].childNodes[1])
      delay =>
        ok spy.called
