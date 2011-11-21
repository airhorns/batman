QUnit.module "Batman.Event",
  setup: ->
    @ottawaWeather = {}
    @rain = new Batman.Event(@ottawaWeather, 'rain')

test "new Batman.Event(base, key) constructs an event object", ->
  equal @rain.base, @ottawaWeather
  equal @rain.key, "rain"

test "fire(args) calls each handler with args in the context of the event's base", ->
  @rain.addHandler(h1 = createSpy())
  @rain.addHandler(h2 = createSpy())

  @rain.fire(1,2,3)

  equal h1.callCount, 1
  equal h1.lastCallContext, @ottawaWeather
  deepEqual h1.lastCallArguments, [1,2,3]

  equal h2.callCount, 1
  equal h2.lastCallContext, @ottawaWeather
  deepEqual h2.lastCallArguments, [1,2,3]

test "if .oneShot is true, fire(args) calls each existing handler right now, then calls any future handler as soon as it's added, and fire(args) then does nothing", ->
  @rain.oneShot = true
  @rain.addHandler(h1 = createSpy())
  @rain.addHandler(h2 = createSpy())

  @rain.fire(1,2,3)

  equal h1.callCount, 1
  equal h1.lastCallContext, @ottawaWeather
  deepEqual h1.lastCallArguments, [1,2,3]

  equal h2.callCount, 1
  equal h2.lastCallContext, @ottawaWeather
  deepEqual h2.lastCallArguments, [1,2,3]

  @rain.addHandler(h3 = createSpy())

  equal h1.callCount, 1
  equal h2.callCount, 1

  equal h3.callCount, 1
  equal h3.lastCallContext, @ottawaWeather
  deepEqual h3.lastCallArguments, [1,2,3]

  @rain.fire(3,2,1)

  equal h1.callCount, 1
  equal h2.callCount, 1
  equal h3.callCount, 1


test "isPrevented() returns true if prevent() has been called more times than allow()", ->
  equal @rain.prevent(), 1
  equal @rain.isPrevented(), true

  equal @rain.allow(), 0
  equal @rain.isPrevented(), false

  equal @rain.prevent(), 1
  equal @rain.prevent(), 2
  equal @rain.allow(), 1
  equal @rain.isPrevented(), true

  equal @rain.allow(), 0
  equal @rain.isPrevented(), false

test "fire() only calls handlers if isPrevented() returns false", ->
  @rain.addHandler(handler = createSpy())
  @rain.isPrevented = -> yes
  @rain.fire()
  equal handler.called, no

test "isEqual(other) returns true when other is an event with the same base and key", ->
  moreRain = new Batman.Event(@ottawaWeather, 'rain')
  ok @rain isnt moreRain
  strictEqual @rain.isEqual(moreRain), true
  strictEqual moreRain.isEqual(@rain), true

  strictEqual @rain.isEqual(base: @ottawaWeather, key: 'rain'), false
  strictEqual @rain.isEqual(new Batman.Event(@ottawaWeather, 'snow')), false
  strictEqual @rain.isEqual(new Batman.Event({}, 'rain')), false



