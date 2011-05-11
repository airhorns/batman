if window?
  exports = window
else
  exports = global
  exports.window = jsdom().createWindow()

class Spy
  constructor: (original) ->
    @called = false
    @callCount = 0
    @calls = []
    @original = original
    @fixedReturn = false

  whichReturns: (value) ->
    @fixedReturn = true
    @fixedReturnValue = value
    @

createSpy = (original) ->
  spy = new Spy

  f = (args...) ->
    f.called = true
    f.callCount++
    f.lastCall =
      object: this
      arguments: args

    f.lastCallArguments = f.lastCall.arguments
    f.calls.push f.lastCall

    unless f.fixedReturn
      f.original?.call(this, args...)
    else
      f.fixedReturnValue

  for k, v of spy
    f[k] = v

  f

spyOn = (obj, method) ->
  obj[method] = createSpy(obj[method])

exports.createSpy = createSpy
exports.spyOn = spyOn
