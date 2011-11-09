Batman = require './../../../../lib/batman'
Watson = require 'watson'
Random = require '../lib/number_generator'
Clunk = require '../lib/clunk'

# Make Iterator defer DOM touches every 50 ms.
# Needed for the ::deferEvery settings below.
Watson.ensureCommitted '7a418aea67be0b79ce11fd5616bd4627f4e576d9', ->
  jsdom = require 'jsdom'

  global.window = jsdom.jsdom("<html><head><script></script></head><body></body></html>").createWindow()
  global.document = window.document

  loopSource = '''
  <div data-foreach-obj="objects">
    <span data-bind="obj"></span>
    <span data-bind="obj"></span>
    <span data-bind="obj"></span>
    <span data-bind="obj"></span>
    <span data-bind="obj"></span>
    <span data-bind="obj"></span>
  </div>
  '''

  Batman.Renderer::deferEvery = false
  if Batman.DOM.IteratorBinding?
    Batman.DOM.IteratorBinding::deferEvery = false

  node = document.createElement 'div'
  node.innerHTML = loopSource

  objects = new Batman.Set([0...50]...)
  context = Batman({objects})

  view = new Batman.View
    contexts: [context]
    node: node

  run = ->
    Watson.trackMemory 'view memory usage: loop rendering', 1000, 5, (i) ->
      objects.add(i)
      objects.remove(Math.max(i - 10, 0))

  if view.on?
    view.on 'ready', run
  else
    view.ready run
