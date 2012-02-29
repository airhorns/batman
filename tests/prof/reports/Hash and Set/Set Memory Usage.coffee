helpers = require 'sha_summarizer'

header "Set Memory Usage"

keys = ["set memory usage", "simple set memory usage"]
klass = Resultset.build 'name', 'value', ->
  @push ["Set", "set memory usage"]
  @push ["SimpleSet", "simple set memory usage"]

param "key", select(klass), label: "Set class:", updateOnChange: true

shas = helpers.getAvailableShas(keys)

linechart helpers.summarizeShasForKey(shas, params.key)
