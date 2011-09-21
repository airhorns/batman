oldSend = Batman.Request::send

QUnit.module 'Batman.Request'
  setup: ->
    @send = Batman.Request::send = createSpy()
  teardown: ->
    Batman.Request::send = oldSend

test 'should not fire if not given a url', ->
  new Batman.Request
  ok !@send.called

asyncTest 'should request a url with default get', 2, ->
  new Batman.Request
    url: 'some/test/url.html'

  delay =>
    req = @send.lastCallContext
    equal req.url, 'some/test/url.html'
    equal req.method, 'get'

asyncTest 'should request a url with a different method', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    method: 'post'

  delay =>
    req = @send.lastCallContext
    equal req.method, 'post'

asyncTest 'should request a url with data', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    data:
      a: "b"
      c: 1

  delay =>
    req = @send.lastCallContext
    deepEqual req.data, {a: "b", c: 1}

asyncTest 'should call the success callback if the request was successful', 1, ->
  observer = createSpy()
  req = new Batman.Request
    url: 'some/test/url.html'
  req.success(observer)

  delay =>
    req = @send.lastCallContext
    req.success('some test data')

    delay =>
      deepEqual observer.lastCallArguments, ['some test data']

if typeof FormData isnt 'undefined'
  oldFormData = FormData
else
  oldFormData = {}

class MockFormData extends MockClass
  constructor: ->
    super
    @appended = []
    @appends = 0
  append: (k, v) ->
    @appends++
    @appended.push [k, v]

container = (if typeof IN_NODE isnt undefined && IN_NODE then global else window)
QUnit.module 'Batman.Request: serializing to FormData'
  setup: ->
    container.FormData = MockFormData
    MockFormData.reset()
  teardown: ->
    container.FormData = oldFormData

test 'should serialize simple data to FormData objects', ->
  object =
    foo: "bar"

  formData = Batman.Request.objectToFormData(object)
  deepEqual formData.appended, [["foo", "bar"]]

test 'should serialize array data to FormData objects', ->
  object =
    foo: ["bar", "baz"]

  formData = Batman.Request.objectToFormData(object)
  deepEqual formData.appended, [["foo[]", "bar"], ["foo[]", "baz"]]

test 'should serialize object data to FormData objects', ->
  object =
    foo:
      bar: "baz"
      qux: "corge"

  formData = Batman.Request.objectToFormData(object)
  deepEqual formData.appended, [["foo[bar]", "baz"], ["foo[qux]", "corge"]]

test 'should serialize nested object and array data to FormData objects', ->
  object =
    foo:
      bar: ["baz", "qux"]
    corge: [{ding: "dong"}, {walla: "walla"}]

  formData = Batman.Request.objectToFormData(object)
  deepEqual formData.appended, [["foo[bar][]", "baz"], ["foo[bar][]", "qux"], ["corge[][ding]", "dong"], ["corge[][walla]", "walla"]]


