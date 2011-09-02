class Tracker extends Batman.Object
  constructor: ->
    @_suites = []

  @accessor 'suites'
    set: (suite) -> @_suites.push suite
    get: -> @_suites

class Suite extends Batman.Object
  constructor: (suite) ->
    @set('suite', suite)
    @_benches = []

  benches: @property
    set: (bench) -> @_benches.push bench
    get: -> @_benches

window.SuiteTracker = new Tracker

for suite in BENCH_SUITES
  s = new Suite(suite)
  SuiteTracker.suites s

  suite.on 'cycle', (bench) ->
    console.log String(bench)
    s.benches bench

  suite.on 'complete', () ->
    console.log  'Fastest is ' + this.filter('fastest').pluck('name')

  suite.run()
