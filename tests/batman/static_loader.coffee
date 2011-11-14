jQuery.ajax
  url: window.location.toString().replace('test_static', 'test')
  success: (html) ->
    div = document.createElement('div')
    div.innerHTML = html
    jsScripts = $.makeArray($('script[src*=".coffee"]', div)).map (element) ->
      $(element).attr('src').replace('.coffee', '.js')

    head.js jsScripts..., ->
      Batman.exportGlobals()
      QUnit.start()

  error: -> throw new Error("Couldn't load test.html!")

