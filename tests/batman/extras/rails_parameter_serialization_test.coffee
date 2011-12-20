QUnit.module "Batman.Rails: form data serialization"

test "it should not include indicies for array objects", ->
  data =
    foo: [{a: "b"},{c: 10}]

  equal decodeURIComponent(jQuery.param(data)), "foo[0][a]=b&foo[1][c]=10"
  equal decodeURIComponent(Batman.RailsStorage::_serializeToFormData(data)), "foo[][a]=b&foo[][c]=10"
