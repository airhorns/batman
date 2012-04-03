helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module "Batman.View subclasses: argument declaration and passing"

test "should allow class level declaration of arguments", ->
  class TestView extends Batman.View
    @option 'keyA', 'keyB', "notgiven"

  node = $('<div data-view-keyA="one" data-view-keyB="two"/>')[0]
  context = Batman one: "foo", two: "bar"
  view = new TestView({node, context})
  equal view.get('keyA'), "foo"
  equal view.get('keyB'), "bar"
  equal view.get('notgiven'), undefined

test "should allow keypaths as argument definitions", ->
  class TestView extends Batman.View
    @option 'test'

  node = $('<div data-view-test="foo.bar.baz" />')[0]
  context = Batman
    foo: Batman
      bar: Batman
        baz: "qux"

  view = new TestView({node, context})
  equal view.get('test'), "qux"

test "should track keypath argument changes and update the property on the view", ->
  class TestView extends Batman.View
    @option 'keyA', 'keyB'

  node = $('<div data-view-keyA="one" data-view-keyB="two"/>')[0]
  context = Batman one: "foo", two: "bar"
  view = new TestView({node, context})
  equal view.get('keyA'), "foo"
  equal view.get('keyB'), "bar"
  context.set 'one', 10
  equal view.get('keyA'), 10
  equal view.get('keyB'), "bar"

asyncTest "should make the arguments available in the context of the view", ->
  class TestView extends Batman.View
    @option 'viewKey'

  source = '<div data-view="TestView" data-view-viewKey="test"><p data-bind="viewKey"></p></div>'
  context = Batman({TestView})

  helpers.render source, context, (node) =>
    equal $('p', node).html(), ""
    context.set "test", "foo"
    equal $('p', node).html(), "foo"
    context.set "test", "bar"
    equal $('p', node).html(), "bar"
    QUnit.start()

test "should recreate argument bindings if the view's node changes", ->
  class TestView extends Batman.View
    @option 'keyA', 'keyB'

  initalNode = $('<div data-view-keyA="one" data-view-keyB="two"/>')[0]
  newNode    = $('<div data-view-keyA="two" data-view-keyB="one"/>')[0]

  context = Batman one: "foo", two: "bar"
  view = new TestView({node: initalNode, context})
  equal view.get('keyA'), "foo"
  equal view.get('keyB'), "bar"

  view.set 'node', newNode
  equal view.get('keyA'), "bar"
  equal view.get('keyB'), "foo"
