BENCH_SUITES.push suite = new Benchmark.Suite

# add tests
suite.add 'RegExp#test', () ->
  /o/.test('Hello World!')

suite.add 'String#indexOf', () ->
  'Hello World!'.indexOf('o') > -1

suite.add 'String#match', () ->
  !!'Hello World!'.match(/o/)


