helpers = if typeof require is 'undefined' then window.viewHelpers else require './view_helper'

QUnit.module 'Batman.View rendering formfor'
  setup: ->
    @User = class User extends MockClass
      name: 'default name'

asyncTest 'it should pull in objects for form rendering', 1, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''
  context =
    instanceOfUser: new @User

  node = helpers.render source, context, (node) ->
    equals $('input', node).val(), "default name"
    QUnit.start()

asyncTest 'it should update objects when form rendering', 1, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''
  context =
    instanceOfUser: new @User

  node = helpers.render source, context, (node) =>
    $('input', node).val('new name')
    # IE8 inserts explicit text nodes
    childNode = if node[0].childNodes[1].nodeName != '#text' then node[0].childNodes[1] else node[0].childNodes[0]
    helpers.triggerChange(childNode)
    delay =>
      equals @User.lastInstance.name, "new name"


asyncTest 'it should update the context for the form if the context changes', 2, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''
  context = new Batman.Object
    instanceOfUser: null

  node = helpers.render source, context, (node) =>
    equals $('input', node).val(), ""
    context.set 'instanceOfUser', new @User
    delay =>
      equals $('input', node).val(), "default name"
