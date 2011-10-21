module.exports = class RandomNumberGenerator
  A:48271
  M: 2147483647
  Q: @::M / @::A
  R: @::M % @::A
  oneOverM: 1.0 / @::M

  constructor: (@min = 0, @max = 1, @seed) ->
    unless @seed?
      d = new Date()
      @seed = 2345678901 + (d.getSeconds() * 0xFFFFFF) + (d.getMinutes() * 0xFFFF)

    @delta = @max - @min

  next: ->
    hi = @seed / @Q
    lo = @seed % @Q
    test = @A * lo - @R * hi
    if test > 0
      @seed = test
    else
      @seed = test + @M

    next = @seed * @oneOverM
    Math.round(@delta * next + @min)
