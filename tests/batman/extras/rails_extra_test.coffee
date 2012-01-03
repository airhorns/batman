QUnit.module "Batman.Rails: form data serialization"

test "it should not include indicies for array objects", ->
  data =
    foo: [{a: "b"},{c: 10}]

  equal decodeURIComponent(jQuery.param(data)), "foo[0][a]=b&foo[1][c]=10"
  equal decodeURIComponent(Batman.RailsStorage::_serializeToFormData(data)), "foo[][a]=b&foo[][c]=10"

QUnit.module "Batman.Rails: date encoding"

dateEqual = (a, b, args...) ->
  equal a.getTime(), b.getTime(), args...

test "it should parse ISO 8601 dates", ->
  dateEqual Batman.Encoders.railsDate.decode("2012-01-03T13:35:06"), new Date("Tues, 03 Jan 2012 13:35:06")

test "it should parse ISO 8601 dates with timezones", ->
  dateEqual Batman.Encoders.railsDate.decode("2012-01-03T13:35:06-05:00"), new Date(1325615706000)
  dateEqual Batman.Encoders.railsDate.decode("2012-01-03T13:35:06-07:00"), new Date(1325622906000)
