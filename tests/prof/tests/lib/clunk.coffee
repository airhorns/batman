Batman = require './../../../../lib/batman'

module.exports = class Clunk extends Batman.Object
  constructor: ->
    @foo = 'bar'
    @bar = {foo: 'bar'}
    @baz = 32412312312
    @qux = {}
    super
