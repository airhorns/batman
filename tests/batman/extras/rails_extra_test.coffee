QUnit.module "Batman.Rails: form data serialization"

test "it should not include indicies for array objects", ->
  data =
    foo: [{a: "b"},{c: 10}]

  equal decodeURIComponent(jQuery.param(data)), "foo[0][a]=b&foo[1][c]=10"
  equal decodeURIComponent(Batman.RailsStorage::_serializeToFormData(data)), "foo[][a]=b&foo[][c]=10"

oldOffset = Batman.Encoders.railsDate.defaultTimezoneOffset
QUnit.module "Batman.Rails: date encoding"
  teardown: ->
    Batman.Encoders.railsDate.defaultTimezoneOffset = oldOffset

dateEqual = (a, b, args...) ->
  equal a.getTime(), b.getTime(), args...

test "it should parse ISO 8601 dates", ->
  # Date not during DST
  Batman.Encoders.railsDate.defaultTimezoneOffset = 300
  dateEqual Batman.Encoders.railsDate.decode("2012-01-03T13:35:06"), new Date("Tues, 03 Jan 2012 13:35:06 EST")
  # Date during DST
  Batman.Encoders.railsDate.defaultTimezoneOffset = 240
  dateEqual Batman.Encoders.railsDate.decode("2012-04-13T13:35:06"), new Date("Sun, 13 Apr 2012 13:35:06 EDT")

test "it should parse ISO 8601 dates with timezones", ->
  dateEqual Batman.Encoders.railsDate.decode("2012-01-03T13:35:06-05:00"), new Date(1325615706000)
  dateEqual Batman.Encoders.railsDate.decode("2012-01-03T13:35:06-07:00"), new Date(1325622906000)

