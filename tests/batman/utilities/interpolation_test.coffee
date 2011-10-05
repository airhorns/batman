QUnit.module 'Batman.helpers.interpolate'

test 'should interpolate simple values', ->
  equal Batman.helpers.interpolate("%{one} %{two}, %{three}", {one: "one", two: 2, three: false}), "one 2, false"

test 'should interpolate counts into a string', ->
  equal Batman.helpers.interpolate("%{one}, %{count}", {one: "one", count: 2}), "one, 2"
