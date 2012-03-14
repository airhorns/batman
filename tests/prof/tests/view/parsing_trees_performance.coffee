Batman = require '../../../../lib/batman'
Watson = require 'watson'
jsdom = require 'jsdom'

global.window = jsdom.jsdom("<html><head><script></script></head><body></body></html>").createWindow()
global.window.Benchmark = Watson.Benchmark
global.document = window.document

Batman.Renderer::deferEvery = 0

div = (text) ->
  node = document.createElement('div')
  node.innerHTML = text if text?
  node

Watson.benchmark 'parseNode function', (error, suite) ->
  throw error if error

  do ->
    source = ("<div></div>" for i in [1..1000]).join('')
    node = div(source)
    context = Batman.RenderContext.base

    suite.add '1000 divs without bindings', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  do ->
    source = ('<div data-test="yes"></div>' for i in [1..1000]).join('')
    node = div(source)
    context = Batman.RenderContext.base

    Batman.DOM.readers.test = -> true

    suite.add '1000 divs with one binding', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  do ->
    divSource = '<div ' + ("data-test#{i}=\"yes\"" for i in [1..10]).join(' ') + "></div>"
    source = (divSource for i in [1..1000]).join('')
    node = div(source)
    context = Batman.RenderContext.base

    for i in [1..10]
      Batman.DOM.readers["test#{i}"] = -> true

    suite.add '1000 divs with 10 bindings', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  do ->
    divSource = '<div ' + ("data-test#{i}-test=\"yes\"" for i in [1..10]).join(' ') + "></div>"
    source = (divSource for i in [1..1000]).join('')
    node = div(source)
    context = Batman.RenderContext.base

    for i in [1..10]
      Batman.DOM.attrReaders["test#{i}"] = -> true

    suite.add '1000 divs with 10 attribute bindings', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  do ->
    node = div()
    for i in [1..10]
      childA = div()
      for j in [1..5]
        childB = div()
        for k in [1..10]
          childC = div()
          for l in [1..2]
            childC.appendChild div()
          childB.appendChild childC
        childA.appendChild childB
      node.appendChild childA

    context = Batman.RenderContext.base

    suite.add '1000 deeply nested divs', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  do ->
    divWithBinding = ->
      x = div(arguments...)
      x.setAttribute('data-test', 'yes')
      x

    node = divWithBinding()
    for i in [1..10]
      childA = divWithBinding()
      for j in [1..5]
        childB = divWithBinding()
        for k in [1..10]
          childC = divWithBinding()
          for l in [1..2]
            childC.appendChild divWithBinding()
          childB.appendChild childC
        childA.appendChild childB
      node.appendChild childA

    context = Batman.RenderContext.base
    Batman.DOM.readers.test = -> true

    suite.add '1000 deeply nested divs with one binding', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  do ->
    divWithBinding = ->
      x = div(arguments...)
      for i in [1..10]
        x.setAttribute("data-test#{i}", 'yes')
      x

    node = divWithBinding()
    for i in [1..10]
      childA = divWithBinding()
      for j in [1..5]
        childB = divWithBinding()
        for k in [1..10]
          childC = divWithBinding()
          for l in [1..2]
            childC.appendChild divWithBinding()
          childB.appendChild childC
        childA.appendChild childB
      node.appendChild childA

    context = Batman.RenderContext.base
    for i in [1..10]
      Batman.DOM.readers["test#{i}"] = -> true

    suite.add '1000 deeply nested divs with 10 bindings', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  do ->
    divWithBinding = ->
      x = div(arguments...)
      for i in [1..10]
        x.setAttribute("data-test#{i}-test", 'yes')
      x

    node = divWithBinding()
    for i in [1..10]
      childA = divWithBinding()
      for j in [1..5]
        childB = divWithBinding()
        for k in [1..10]
          childC = divWithBinding()
          for l in [1..2]
            childC.appendChild divWithBinding()
          childB.appendChild childC
        childA.appendChild childB
      node.appendChild childA

    context = Batman.RenderContext.base
    for i in [1..10]
      Batman.DOM.attrReaders["test#{i}"] = -> true

    suite.add '1000 deeply nested divs with 10 attribute bindings', (deferred) ->
      renderer = new Batman.Renderer(node, (->), context, {})
      Batman.clearImmediate renderer.immediate
      renderer.start()

  suite.run()
