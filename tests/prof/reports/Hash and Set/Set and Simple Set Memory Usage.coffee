helpers = require 'sha_summarizer'

header "Set Memory Usage"

keys = ["set memory usage with objects", "set memory usage with strings", "simple set memory usage with objects", "simple set memory usage with strings"]

klass = Resultset.build 'name', 'value', ->
  @push ["Set", "set memory usage"]
  @push ["SimpleSet", "simple set memory usage"]

param "key", select(klass), label: "Set class:", updateOnChange: true

shas = helpers.getAvailableShas(keys)

header "Object members"
linechart helpers.summarizeShasForKey(shas, params.key + " with objects")

header "String members"
linechart helpers.summarizeShasForKey(shas, params.key + " with strings")
