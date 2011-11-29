dataTests = (elem) ->
  getCacheLength = ->
    cacheLength = 0
    for i of Batman.cache
      ++cacheLength
    cacheLength

  assert.equal Batman.data(elem, "foo"), undefined, "No data exists initially"
  assert.strictEqual Batman.hasData(elem), false, "Batman.hasData agrees no data exists initially"

  dataObj = Batman.data(elem)
  assert.equal typeof dataObj, "object", "Calling data with no args gives us a data object reference"
  assert.strictEqual Batman.data(elem), dataObj, "Calling Batman.data returns the same data object when called multiple times"
  assert.strictEqual Batman.hasData(elem), false, "Batman.hasData agrees no data exists even when an empty data obj exists"

  dataObj.foo = "bar"
  assert.equal Batman.data(elem, "foo"), "bar", "Data is readable by Batman.data when set directly on a returned data object"
  assert.strictEqual Batman.hasData(elem), true, "Batman.hasData agrees data exists when data exists"

  Batman.data elem, "foo", "baz"
  assert.equal Batman.data(elem, "foo"), "baz", "Data can be changed by Batman.data"
  assert.equal dataObj.foo, "baz", "Changes made through Batman.data propagate to referenced data object"

  Batman.data elem, "foo", undefined
  assert.equal Batman.data(elem, "foo"), "baz", "Data is not unset by passing undefined to Batman.data"

  Batman.data elem, "foo", null
  assert.strictEqual Batman.data(elem, "foo"), null, "Setting null using Batman.data works OK"

  Batman.data elem, "foo", "foo1"
  Batman.data elem,
    bar: "baz"
    boom: "bloz"

  assert.strictEqual Batman.data(elem, "foo"), "foo1", "Passing an object extends the data object instead of replacing it"
  assert.equal Batman.data(elem, "boom"), "bloz", "Extending the data object works"

  Batman._data elem, "foo", "foo2"
  assert.equal Batman._data(elem, "foo"), "foo2", "Setting internal data works"
  assert.equal Batman.data(elem, "foo"), "foo1", "Setting internal data does not override user data"

  internalDataObj = Batman.data(elem, Batman.expando)
  assert.strictEqual Batman._data(elem), internalDataObj, "Internal data object is accessible via Batman.expando property"
  assert.notStrictEqual dataObj, internalDataObj, "Internal data object is not the same as user data object"
  assert.strictEqual elem.boom, undefined, "Data is never stored directly on the object"

  Batman.removeData elem, "foo"
  assert.strictEqual Batman.data(elem, "foo"), undefined, "Batman.removeData removes single properties"

  Batman.removeData elem
  assert.strictEqual Batman.data(elem, Batman.expando), internalDataObj, "Batman.removeData does not remove internal data if it exists"

  Batman.removeData elem, undefined, true
  assert.strictEqual Batman.data(elem, Batman.expando), undefined, "Batman.removeData on internal data works"
  assert.strictEqual Batman.hasData(elem), false, "Batman.hasData agrees all data has been removed from object"

  Batman._data elem, "foo", "foo2"
  assert.strictEqual Batman.hasData(elem), true, "Batman.hasData shows data exists even if it is only internal data"

  Batman.data elem, "foo", "foo1"
  assert.equal Batman._data(elem, "foo"), "foo2", "Setting user data does not override internal data"

  Batman.removeData elem, undefined, true
  assert.equal Batman.data(elem, "foo"), "foo1", "Batman.removeData for internal data does not remove user data"

  if elem.nodeType
    oldCacheLength = getCacheLength()
    Batman.removeData elem, "foo"
    assert.equal getCacheLength(), oldCacheLength - 1, "Removing the last item in the data object destroys it"
  else
    Batman.removeData elem, "foo"
    actual = elem[Batman.expando]

  Batman.data elem, "foo", "foo1"
  Batman._data elem, "foo", "foo2"
  assert.equal Batman.data(elem, "foo"), "foo1", "(sanity check) Ensure data is set in user data object"
  assert.equal Batman._data(elem, "foo"), "foo2", "(sanity check) Ensure data is set in internal data object"

  Batman.removeData elem, "foo", true
  assert.strictEqual Batman.data(elem, Batman.expando), undefined, "Removing the last item in internal data destroys the internal data object"

  Batman._data elem, "foo", "foo2"
  assert.equal Batman._data(elem, "foo"), "foo2", "(sanity check) Ensure data is set in internal data object"

  Batman.removeData elem, "foo"
  assert.equal Batman._data(elem, "foo"), "foo2", "(sanity check) Batman.removeData for user data does not remove internal data"
  if elem.nodeType
    oldCacheLength = getCacheLength()
    Batman.removeData elem, "foo", true
    assert.equal getCacheLength(), oldCacheLength - 1, "Removing the last item in the internal data object also destroys the user data object when it is empty"
  else
    Batman.removeData elem, "foo", true
    actual = elem[Batman.expando]

suite 'Batman.Data', ->

  test "expando", ->
    assert.equal "expando" of Batman, true, "Batman is exposing the expando"

  test "Batman.data", ->
    div = document.createElement("div")
    dataTests div
    dataTests document

  test "Batman.acceptData", ->
    assert.ok Batman.acceptData(document), "document"
    assert.ok Batman.acceptData(document.documentElement), "documentElement"
    assert.ok Batman.acceptData({}), "object"
    assert.ok not Batman.acceptData(document.createElement("embed")), "embed"
    assert.ok not Batman.acceptData(document.createElement("applet")), "applet"
    flash = document.createElement("object")
    flash.setAttribute "classid", "clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
    assert.ok Batman.acceptData(flash), "flash"
    applet = document.createElement("object")
    applet.setAttribute "classid", "clsid:8AD9C840-044E-11D1-B3E9-00805F499D93"
    assert.ok not Batman.acceptData(applet), "applet"

  test "Batman.removeData", ->
    div = document.createElement("div")
    Batman.data div, "test", "testing"
    Batman.removeData div, "test"
    assert.equal Batman.data(div, "test"), undefined, "Check removal of data"
    Batman.data div, "test2", "testing"
    Batman.removeData div
    assert.ok not Batman.data(div, "test2"), "Make sure that the data property no longer exists."
    assert.ok not div[Batman.expando], "Make sure the expando no longer exists, as well."
    obj = {}
    Batman.data obj, "test", "testing"
    assert.equal Batman.data(obj, "test"), "testing", "verify data on plain object"
    Batman.removeData obj, "test"
    assert.equal Batman.data(obj, "test"), undefined, "Check removal of data on plain object"
    Batman.data window, "BAD", true
    Batman.removeData window, "BAD"
    assert.ok not Batman.data(window, "BAD"), "Make sure that the value was not still set."

  test "Batman.data should not miss data with preset hyphenated property names", ->
    div = document.createElement 'div'
    div.id = 'hyphened'
    test =
      camelBar: "camelBar"
      "hyphen-foo": "hyphen-foo"

    Batman.data div, test
    for k, v of test
      assert.equal Batman.data(div, k), k, "data with property '" + k + "' was correctly found"
