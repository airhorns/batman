QUnit.module "Batman.EventEmitter"
  setup: ->
    @prototypeRainHandler = prototypeRainHandler = createSpy()
    @WeatherSystem = class WeatherSystem
      Batman.mixin @::, Batman.EventEmitter
      @::on 'rain', prototypeRainHandler
    @ottawaWeather = new WeatherSystem
    @rain = @ottawaWeather.event('rain')

test "firing an event calls the prototype's handlers for that event too", ->
  @rain.addHandler(h1 = createSpy())
  @rain.addHandler(h2 = createSpy())

  @rain.fire(1,2,3)

  equal h1.callCount, 1
  #equal h1.lastCallContext, @ottawaWeather
  deepEqual h1.lastCallArguments, [1,2,3]

  equal h2.callCount, 1
  equal h2.lastCallContext, @ottawaWeather
  deepEqual h2.lastCallArguments, [1,2,3]

  equal @prototypeRainHandler.callCount, 1
  equal @prototypeRainHandler.lastCallContext, @ottawaWeather
  deepEqual @prototypeRainHandler.lastCallArguments, [1,2,3]


test "events inherited from ancestors retain oneshot status", ->
  @WeatherSystem::event('snow').oneShot = true

  ok @ottawaWeather.event('snow').oneShot

  class TestWeatherSystem extends @WeatherSystem

  ok TestWeatherSystem::event('snow').oneShot
  ok (new TestWeatherSystem).event('snow').oneShot
