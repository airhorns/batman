Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'
Random = require '../lib/number_generator'

Batman.developer?.suppress()
generator = new Random(0, 10, 3000)

strings = []
clunks = for i in [0...100]
  number = generator.next()
  strings.push "foooo" + number
  new Clunk({number})

Watson.benchmark 'set performance', (error, suite) ->
  throw error if error

  do ->
    set = new Batman.Set
    for clunk in clunks
      set.add clunk

    suite.add 'object member iteration', () ->
      for i in [0..100]
        set.forEach (item) ->
      true

  do ->
    set = new Batman.Set
    suite.add 'object member adding', () ->
      for clunk in clunks
        set.add clunk
      true

  do ->
    getSet = ->
      set = new Batman.Set
      set.add(clunk) for clunk in clunks
      set

    set = getSet()

    suite.add 'object member removal', () ->
      for clunk in clunks
        set.remove(clunk)
      true
    , {
      onCycle: -> set = getSet()
    }

  do ->
    set = new Batman.Set
    set.add clunk for clunk in clunks

    suite.add 'object membership check', ->
      for clunk in clunks
        set.has clunk
      true

  do ->
    moreClunks = for i in [0..100]
      number = generator.next()
      new Clunk({number})

    sortedMoreClunks = moreClunks.sort (a, b) -> a.number - b.number

    getSet = ->
      set = new Batman.Set
      set.add(clunk) for clunk in clunks
      set.add(clunk) for clunk in moreClunks
      set

    set = getSet()

    suite.add 'haystack object member removal', () ->
      # Remove clunks in a deterministic but random order
      for clunk in sortedMoreClunks
        set.remove(clunk)
      true
    , {
      onCycle: -> set = getSet()
    }

  do ->
    set = new Batman.Set
    for string in strings
      set.add string

    suite.add 'string member iteration', () ->
      for i in [0..100]
        set.forEach (string) ->
      true

  do ->
    set = new Batman.Set
    suite.add 'string member adding', () ->
      for string in strings
        set.add string
      true

  do ->
    getSet = ->
      set = new Batman.Set
      set.add(string) for string in strings
      set

    set = getSet()

    suite.add 'string member removal', () ->
      for string in strings
        set.remove(string)
      true
    , {
      onCycle: -> set = getSet()
    }

  do ->
    set = new Batman.Set
    set.add string for string in strings

    suite.add 'string membership check', () ->
      for string in strings
        set.has string
      true

  do ->
    moreStrings = ("foooo" + i for i in [0..100])
    sortedMoreStrings = moreStrings.sort (a, b) -> if generator.next() >= 5 then 1 else -1

    getSet = ->
      set = new Batman.Set
      set.add(string) for string in strings
      set.add(string) for string in moreStrings
      set

    set = getSet()

    suite.add 'haystack string member removal', () ->
      # Remove clunks in a deterministic but random order
      for string in sortedMoreStrings
        set.remove(string)
      true
    , {
      onCycle: -> set = getSet()
    }

  suite.run()
