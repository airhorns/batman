Batman = require './../../../lib/batman'
Watson = require 'watson'
microtime = require 'microtime'
jsdom = require 'jsdom'

global.window = jsdom.jsdom("<html><head><script></script></head><body></body></html>").createWindow()
global.window.Benchmark = require 'benchmark'
global.document = window.document

simpleSource = '''
<div data-bind="foo"></div>
'''

loopSource = '''
<div data-foreach-obj="objects">
  <span data-bind="obj"></span>
  <span data-bind="obj | times 10"></span>
  <span data-bind="obj | times 100"></span>
</div>
'''

Batman.Renderer::deferEvery = false
Batman.Filters.times = (multiplicand, multiplier) -> multiplicand * multiplier

Watson.trackMemory 'view memory usage: simple', 100, 1, (i) ->
  node = document.createElement 'div'
  node.innerHTML = loopSource
  context = Batman(objects: new Batman.Set([0...50]...))

  view = new Batman.View
    contexts: [context]
    node: node

  Batman.DOM.removeNode(node)
