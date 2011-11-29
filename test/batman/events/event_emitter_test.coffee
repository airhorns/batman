suite "Batman.EventEmitter", ->
  prototypeRainHandler = false
  WeatherSystem = false
  ottawaWeather = false
  rain = false

  setup ->
    prototypeRainHandler = createSpy()
    class WeatherSystem
      $mixin @prototype, Batman.EventEmitter
      @::on 'rain', prototypeRainHandler
    ottawaWeather = new WeatherSystem
    rain = ottawaWeather.event('rain')

  test "firing an event calls the prototype's handlers for that event too", ->
    rain.addHandler(h1 = createSpy())
    rain.addHandler(h2 = createSpy())

    rain.fire(1,2,3)

    assert.equal h1.callCount, 1
    assert.equal h1.lastCallContext, ottawaWeather
    assert.deepEqual h1.lastCallArguments, [1,2,3]

    assert.equal h2.callCount, 1
    assert.equal h2.lastCallContext, ottawaWeather
    assert.deepEqual h2.lastCallArguments, [1,2,3]

    assert.equal prototypeRainHandler.callCount, 1
    assert.equal prototypeRainHandler.lastCallContext, ottawaWeather
    assert.deepEqual prototypeRainHandler.lastCallArguments, [1,2,3]
