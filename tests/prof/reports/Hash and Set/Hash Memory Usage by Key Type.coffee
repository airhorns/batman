helpers = require 'sha_summarizer'

header "Simple Hash Memory Usage by Key type"

keys = ["simple hash memory usage with objects", "simple hash memory usage with strings"]
shas = helpers.getAvailableShas(keys)

header "Objects"
linechart helpers.summarizeShasForKey(shas, keys[0])

header "Strings"
linechart helpers.summarizeShasForKey(shas, keys[1])

header "Comparison for first SHA"

linechart helpers.summarizeKeysForSha(keys, shas[0])
