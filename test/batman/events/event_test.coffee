suite "Batman", ->
  suite "Event", ->
    ottawaWeather = false
    rain = false

    setup ->
      ottawaWeather = {}
      rain = new Batman.Event(ottawaWeather, 'rain')

    test "new Batman.Event(base, key) constructs an event object", ->
      assert.equal rain.base, ottawaWeather
      assert.equal rain.key, "rain"

    test "fire(args) calls each handler with args in the context of the event's base", ->
      rain.addHandler(h1 = createSpy())
      rain.addHandler(h2 = createSpy())

      rain.fire(1,2,3)

      assert.equal h1.callCount, 1
      assert.equal h1.lastCallContext, ottawaWeather
      assert.deepEqual h1.lastCallArguments, [1,2,3]

      assert.equal h2.callCount, 1
      assert.equal h2.lastCallContext, ottawaWeather
      assert.deepEqual h2.lastCallArguments, [1,2,3]

    test "if .oneShot is true, fire(args) calls each existing handler right now, then calls any future handler as soon as it's added, and fire(args) then does nothing", ->
      rain.oneShot = true
      rain.addHandler(h1 = createSpy())
      rain.addHandler(h2 = createSpy())

      rain.fire(1,2,3)

      assert.equal h1.callCount, 1
      assert.equal h1.lastCallContext, ottawaWeather
      assert.deepEqual h1.lastCallArguments, [1,2,3]

      assert.equal h2.callCount, 1
      assert.equal h2.lastCallContext, ottawaWeather
      assert.deepEqual h2.lastCallArguments, [1,2,3]

      rain.addHandler(h3 = createSpy())

      assert.equal h1.callCount, 1
      assert.equal h2.callCount, 1

      assert.equal h3.callCount, 1
      assert.equal h3.lastCallContext, ottawaWeather
      assert.deepEqual h3.lastCallArguments, [1,2,3]

      rain.fire(3,2,1)

      assert.equal h1.callCount, 1
      assert.equal h2.callCount, 1
      assert.equal h3.callCount, 1

    test "isPrevented() returns true if prevent() has been called more times than allow()", ->
      assert.equal rain.prevent(), 1
      assert.equal rain.isPrevented(), true

      assert.equal rain.allow(), 0
      assert.equal rain.isPrevented(), false

      assert.equal rain.prevent(), 1
      assert.equal rain.prevent(), 2
      assert.equal rain.allow(), 1
      assert.equal rain.isPrevented(), true

      assert.equal rain.allow(), 0
      assert.equal rain.isPrevented(), false

    test "fire() only calls handlers if isPrevented() returns false", ->
      rain.addHandler(handler = createSpy())
      rain.isPrevented = -> yes
      rain.fire()
      assert.equal handler.called, no

    test "isEqual(other) returns true when other is an event with the same base and key", ->
      moreRain = new Batman.Event(ottawaWeather, 'rain')
      assert.ok rain isnt moreRain
      assert.strictEqual rain.isEqual(moreRain), true
      assert.strictEqual moreRain.isEqual(rain), true

      assert.strictEqual rain.isEqual(base: ottawaWeather, key: 'rain'), false
      assert.strictEqual rain.isEqual(new Batman.Event(ottawaWeather, 'snow')), false
      assert.strictEqual rain.isEqual(new Batman.Event({}, 'rain')), false
