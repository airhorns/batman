suite "Batman", ->
  suite "ParamsReplacer", ->
    navigator = params = replacer = false
    setup ->
      navigator =
        replace: createSpy()
        push: createSpy()
      params = new Batman.Hash
        foo: 'fooVal'
        bar: 'barVal'
      replacer = new Batman.ParamsReplacer(navigator, params)

    test "toObject() delegates to the wrapped params hash",  ->
      assert.deepEqual replacer.toObject(), params.toObject()

    test "get(key) delegates to the wrapped params hash",  ->
      assert.equal replacer.get('foo'), 'fooVal'

    test "set(key, value) delegates to the wrapped params hash and redirects in-place",  ->
      replacer.set('foo', 'newFoo')
      assert.equal params.get('foo'), 'newFoo'
      assert.equal navigator.replace.callCount, 1
      assert.deepEqual navigator.replace.lastCallArguments, [{foo: 'newFoo', bar: 'barVal'}]

    test "unset(key) delegates to the wrapped params hash and redirects in-place",  ->
      replacer.unset('foo')
      assert.equal params.hasKey('foo'), false
      assert.equal navigator.replace.callCount, 1
      assert.deepEqual navigator.replace.lastCallArguments, [{bar: 'barVal'}]

    test "replace(params) delegates to the wrapped params hash and redirects in-place",  ->
      replacer.replace foo: 'newFoo', baz: 'bazVal'
      expected = foo: 'newFoo', baz: 'bazVal'
      assert.deepEqual params.toObject(), expected
      assert.equal navigator.replace.callCount, 1
      assert.deepEqual navigator.replace.lastCallArguments, [expected]

    test "update(params) delegates to the wrapped params hash and redirects in-place",  ->
      replacer.update foo: 'newFoo', baz: 'bazVal'
      expected = foo: 'newFoo', bar: 'barVal', baz: 'bazVal'
      assert.deepEqual params.toObject(), expected
      assert.equal navigator.replace.callCount, 1
      assert.deepEqual navigator.replace.lastCallArguments, [expected]

    test "clear() delegates to the wrapped params hash and redirects in-place",  ->
      replacer.clear()
      assert.deepEqual params.toObject(), {}
      assert.equal navigator.replace.callCount, 1
      assert.deepEqual navigator.replace.lastCallArguments, [{}]

    test "ParamsPusher subclass uses navigator.push to redirect",  ->
      pusher = new Batman.ParamsPusher(navigator, params)
      pusher.set('foo', 'newFoo')
      assert.equal navigator.push.callCount, 1
      assert.deepEqual navigator.push.lastCallArguments, [{foo: 'newFoo', bar: 'barVal'}]

      pusher.unset('foo')
      assert.equal navigator.push.callCount, 2
      assert.deepEqual navigator.push.lastCallArguments, [{bar: 'barVal'}]

      pusher.replace foo: 'newFoo', bar: 'barVal'
      assert.equal navigator.push.callCount, 3
      assert.deepEqual navigator.push.lastCallArguments, [{foo: 'newFoo', bar: 'barVal'}]

      pusher.update foo: 'newerFoo', baz: 'bazVal'
      assert.equal navigator.push.callCount, 4
      assert.deepEqual navigator.push.lastCallArguments, [{foo: 'newerFoo', bar: 'barVal', baz: 'bazVal'}]

      pusher.clear()
      assert.equal navigator.push.callCount, 5
      assert.deepEqual navigator.push.lastCallArguments, [{}]
