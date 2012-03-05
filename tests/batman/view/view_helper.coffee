$ = window.$ unless $
if ! IN_NODE
  exports = window.viewHelpers = {}
else
  global.$ = $
  exports = module.exports

exports.triggerChange = (domNode) ->
  if document.createEvent
    evt = document.createEvent("HTMLEvents")
    evt.initEvent("change", true, true)
    domNode.dispatchEvent(evt)
  else if document.createEventObject
    domNode.fireEvent 'onchange'

exports.triggerFocus = (domNode) ->
  if document.createEvent
    evt = document.createEvent("HTMLEvents")
    evt.initEvent("focus", false, false)
    domNode.dispatchEvent(evt)
  else if document.createEventObject
    domNode.fireEvent 'onfocus'

exports.triggerClick = (domNode, eventName = 'click') ->
  if document.createEvent
    evt = document.createEvent("MouseEvents")
    evt.initMouseEvent(eventName, true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null)
    domNode.dispatchEvent(evt)
  else if document.createEventObject
    domNode.fireEvent 'on'+eventName

exports.triggerDoubleClick = (domNode) ->
  exports.triggerClick domNode, 'dblclick'

keyIdentifiers =
  13: 'Enter'

window.getKeyEvent = _getKeyEvent = (eventName, keyCode) ->
  if document.createEvent
    evt = document.createEvent "KeyboardEvent"

    if evt.initKeyEvent
      evt.initKeyEvent(eventName, true, true, window, 0, 0, 0, 0, keyCode, keyCode)
    else if evt.initKeyboardEvent
      evt.initKeyboardEvent(eventName, true, true, window, keyIdentifiers[keyCode], keyIdentifiers[keyCode], false, false, keyCode, keyCode)
    else
      # JSDOM doesn't yet implement KeyboardEvents...  We'll simulate them instead.
      evt._type = eventName
      evt._bubbles = true
      evt._cancelable = true
      evt._target = window
      evt._currentTarget = null
      evt._keyIdentifier = keyIdentifiers[keyCode]
      evt._keyLocation = keyIdentifiers[keyCode]
      evt.which = evt.keyCode = keyCode

  else if document.createEventObject
    # IE 8 land
    evt = document.createEventObject("KeyboardEvent")
    evt.type = eventName
    evt.cancelBubble = false
    evt.keyCode = keyCode

  evt

exports.triggerKey = (domNode, keyCode, eventNames = ["keydown", "keypress", "keyup"]) ->
  for eventName in eventNames
    event = _getKeyEvent(eventName, keyCode)
    if document.createEvent
      domNode.dispatchEvent event
    else if document.createEventObject
      domNode.fireEvent 'on'+eventName, event

exports.triggerSubmit = (domNode) ->
  if document.createEvent
    evt = document.createEvent('HTMLEvents')
    evt.initEvent('submit', true, true)
    domNode.dispatchEvent(evt)
  else if document.createEventObject
    domNode.fireEvent 'onsubmit'

exports.withNodeInDom = (node, callback) ->
  node = $(node)
  $('body').append(node)
  do callback
  node.remove()

exports.splitAndSortedEquals = (a, b, split = ',') ->
  deepEqual a.split(split).sort(), b.split(split).sort()

# Helper function for rendering a view given a context. Optionally returns a jQuery of the nodes,
# and calls a callback with the same. Beware of the 50ms timeout when rendering views, tests should
# be async and rely on the view.ready one shot event for running assertions.
exports.render = (source, jqueryize = true, context = {}, callback = ->) ->
  node = document.createElement 'div'
  node.innerHTML = source
  unless !!jqueryize == jqueryize
    [context, callback] = [jqueryize, context]
  else
    if typeof context == 'function'
      callback = context

  context = if context.get && context.set then context else Batman(context)
  view = new Batman.View
    context: context
    node: node

  view.on 'ready', ->
    node = if jqueryize then $(view.get('node')).children() else view.get('node')
    callback(node, view)

  view.get('node')
