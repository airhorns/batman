$ = window.$ unless $
if ! IN_NODE
  exports = window.viewHelpers = {}
else
  global.$ = $
  exports = module.exports

exports.triggerChange = (domNode) ->
  evt = document.createEvent("HTMLEvents")
  evt.initEvent("change", true, true)
  domNode.dispatchEvent(evt)

exports.triggerClick = (domNode) ->
  evt = document.createEvent("MouseEvents")
  evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null)
  domNode.dispatchEvent(evt)

keyIdentifers =
  13: 'Enter'

window.getKeyEvent = _getKeyEvent = (eventName, keyCode) ->
  evt = document.createEvent("KeyboardEvent")
  if evt.initKeyEvent
    evt.initKeyEvent(eventName, true, true, window, 0, 0, 0, 0, keyCode, keyCode)
  else if evt.initKeyboardEvent
    evt.initKeyboardEvent(eventName, true, true, window, keyIdentifers[keyCode], keyIdentifers[keyCode])
  else
    # JSDOM doesn't yet implement KeyboardEvents...  We'll simulate them instead.
    evt._type = eventName
    evt._bubbles = true
    evt._cancelable = true
    evt._target = window
    evt._currentTarget = null
    evt._keyIdentifier = keyIdentifers[keyCode]
    evt._keyLocation = keyIdentifers[keyCode]

  evt.which = evt.keyCode = keyCode
  evt

exports.triggerKey = (domNode, keyCode) ->
  domNode.dispatchEvent(_getKeyEvent("keydown", keyCode))
  domNode.dispatchEvent(_getKeyEvent("keypress", keyCode))
  domNode.dispatchEvent(_getKeyEvent("keyup", keyCode))

exports.triggerSubmit = (domNode) ->
  # TODO: Verify portability.
  evt = document.createEvent('HTMLEvents')
  evt.initEvent('submit', true, true)
  domNode.dispatchEvent(evt)

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
    contexts: [Batman({}), context]
    node: node
  view.ready ->
    node = if jqueryize then $(view.get('node')).children() else view.get('node')
    callback(node, view)
  view.get('node')
