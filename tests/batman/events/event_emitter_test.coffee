QUnit.module "Batman.EventEmitter"
  setup: ->
    @prototypeRainHandler = prototypeRainHandler = createSpy()
    @WeatherSystem = class WeatherSystem
      Batman.mixin @::, Batman.EventEmitter
      @::on 'rain', prototypeRainHandler
    @ottawaWeather = new WeatherSystem
    @rain = @ottawaWeather.event('rain')

test "firing an event calls ancestor event handlers for that event too", ->
  secondPrototypeHandler = createSpy()
  class Thunderstorm extends @WeatherSystem
    @::on 'rain', secondPrototypeHandler

  storm = new Thunderstorm
  storm.on 'rain', instanceHandler = createSpy()
  storm.fire('rain', 1,2,3)

  for handler in [instanceHandler, @prototypeRainHandler, secondPrototypeHandler]
    equal handler.callCount, 1
    ok handler.lastCallContext == storm
    deepEqual handler.lastCallArguments, [1,2,3]

test "events inherited from ancestors retain oneshot status", ->
  @WeatherSystem::event('snow').oneShot = true

  ok @ottawaWeather.event('snow').oneShot

  class TestWeatherSystem extends @WeatherSystem

  ok TestWeatherSystem::event('snow').oneShot
  ok (new TestWeatherSystem).event('snow').oneShot
