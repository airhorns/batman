oldSend = Batman.Request::send
oldFile = Batman.container.File

QUnit.module 'Batman.Request'
  setup: ->
    @sendSpy = createSpy()
    Batman.Request::send = @sendSpy
    Batman.container.File = class File
  teardown: ->
    Batman.container.File = oldFile
    Batman.Request::send = oldSend
    @request?.cancel()

test 'hasFileUploads() returns false when the request data has no file uploads', ->
  req = new Batman.Request data:
    user:
      name: 'Jim'
  equal req.hasFileUploads(), false
 
test 'hasFileUploads() returns true when the request data has a file upload in a nested object', ->
  req = new Batman.Request data:
    user:
      avatar: new File()
  equal req.hasFileUploads(), true

test 'hasFileUploads() returns true when the request data has a file upload in a nested array', ->
  req = new Batman.Request data:
    user:
      avatars: [undefined, new File()]
  equal req.hasFileUploads(), true

test 'should not fire if not given a url', ->
  new Batman.Request
  ok !@sendSpy.called

asyncTest 'should request a url with default get', 2, ->
  @request = new Batman.Request
    url: 'some/test/url.html'
    send: @sendSpy
  delay =>
    req = @sendSpy.lastCallContext
    equal req.url, 'some/test/url.html'
    equal req.method, 'GET'

asyncTest 'should request a url with a different method, converting the method to uppercase', 1, ->
  @request = new Batman.Request
    url: 'B/test/url.html'
    method: 'post'
    send: @sendSpy

  delay =>
    req = @sendSpy.lastCallContext
    equal req.method, 'POST'

asyncTest 'should request a url with data', 1, ->
  new Batman.Request
    url: 'some/test/url.html'
    data:
      a: "b"
      c: 1
    send: @sendSpy

  delay =>
    req = @sendSpy.lastCallContext
    deepEqual req.data, {a: "b", c: 1}

asyncTest 'should call the success callback if the request was successful', 2, ->
  postInstantiationObserver = createSpy()
  optionsHashObserver = createSpy()
  req = new Batman.Request
    url: 'some/test/url.html'
    success: optionsHashObserver
    send: @sendSpy

  req.on 'success', postInstantiationObserver

  delay =>
    req = @sendSpy.lastCallContext
    req.fire 'success', 'some test data'

    delay =>
      deepEqual optionsHashObserver.lastCallArguments, ['some test data']
      deepEqual postInstantiationObserver.lastCallArguments, ['some test data']

asyncTest 'should set headers', 2, ->
  new Batman.Request
    url: 'some/test/url.html'
    headers: {'test_header': 'test-value'}
    send: @sendSpy

  delay =>
    req = @sendSpy.lastCallContext
    notEqual req.headers.test_header, undefined
    equal req.headers.test_header, 'test-value'

if typeof Batman.container.FormData isnt 'undefined'
  oldFormData = Batman.container.FormData
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

QUnit.module 'Batman.Request: serializing to FormData'
  setup: ->
    Batman.container.FormData = MockFormData
    MockFormData.reset()

  teardown: ->
    Batman.container.FormData = oldFormData

test 'should serialize array data to FormData objects', ->
  object =
    foo: ["bar", "baz"]

  formData = Batman.Request.objectToFormData(object)
  deepEqual formData.appended, [["foo[]", "bar"], ["foo[]", "baz"]]

test 'should serialize simple data to FormData objects', ->
  object =
    foo: "bar"

  formData = Batman.Request.objectToFormData(object)
  deepEqual formData.appended, [["foo", "bar"]]

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
