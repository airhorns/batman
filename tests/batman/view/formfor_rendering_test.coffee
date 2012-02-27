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
    equals @User.lastInstance.name, "new name"

    QUnit.start()

asyncTest 'it should update the context for the form if the context changes', 2, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''
  context = Batman()

  node = helpers.render source, context, (node) =>
    equals $('input', node).val(), ""
    context.set 'instanceOfUser', new @User
    equals $('input', node).val(), "default name"

    QUnit.start()

asyncTest 'it should add the errors class to an input bound to a field on the subject', 2, ->
  source = '''
  <form data-formfor-user="instanceOfUser">
    <input type="text" data-bind="user.name">
  </form>
  '''

  context = Batman
    instanceOfUser: Batman
      name: ''

  node = helpers.render source, context, (node) =>
    ok !$('input', node).hasClass('error')

    errors = new Batman.ErrorsSet
    errors.add 'name', "can't be blank"
    context.get('instanceOfUser').set 'errors', errors
    ok $('input', node).hasClass('error')

    QUnit.start()

if !IN_NODE # jsdom doesn't support querySelector on elements, so these tests fail.
  asyncTest 'it should add the error list HTML to the default selected node', 3, ->
    source = '''
    <form data-formfor-user="instanceOfUser">
      <div class="errors"></div>
      <input type="text" data-bind="user.name">
    </form>
    '''
    context = Batman
      instanceOfUser: Batman
        name: ''
        errors: new Batman.ErrorsSet

    node = helpers.render source, context, (node) =>
      ok node.find("div.errors ul").length > 0
      context.get('instanceOfUser.errors').add 'name', "can't be blank"
      delay =>
        equal node.find("div.errors li").length, 1
        equal node.find("div.errors li").html(), "name can't be blank"


  asyncTest 'it should only show the errors list when there are errors', 2, ->
    source = '''
    <form data-formfor-user="instanceOfUser">
      <div class="errors"></div>
      <input type="text" data-bind="user.name">
    </form>
    '''
    context = Batman
      instanceOfUser: Batman
        name: ''
        errors: new Batman.ErrorsSet

    node = helpers.render source, context, (node) =>
      equal node.find("div.errors").css('display'), 'none'
      context.get('instanceOfUser.errors').add 'name', "can't be blank"
      delay =>
        equal node.find("div.errors").css('display'), ''

  asyncTest 'it shouldn\'t override already existing showif bindings on the errors list', 2, ->
    source = '''
    <form data-formfor-user="instanceOfUser">
      <div class="errors" data-showif="show?"></div>
      <input type="text" data-bind="user.name">
    </form>
    '''
    context = Batman
      'show?': true
      instanceOfUser: Batman
        name: ''
        errors: new Batman.ErrorsSet

    node = helpers.render source, context, (node) =>
      equal node.find("div.errors").css('display'), ''
      context.get('instanceOfUser.errors').add 'name', "can't be blank"
      delay =>
        equal node.find("div.errors").css('display'), ''

  asyncTest 'it should add the error list HTML to a specified selected node', 3, ->
    source = '''
    <form data-formfor-user="instanceOfUser" data-errors-list="#testy">
      <div class="errors"><div><span id="testy"></span></div></div>
      <input type="text" data-bind="user.name">
    </form>
    '''
    context = Batman
      instanceOfUser: Batman
        name: ''
        errors: new Batman.ErrorsSet

    node = helpers.render source, context, (node) =>
      ok node.find("#testy ul").length > 0
      context.get('instanceOfUser.errors').add 'name', "can't be blank"
      delay =>
        equal node.find("#testy li").length, 1
        equal node.find("#testy li").html(), "name can't be blank"
