helpers = require 'sha_summarizer'

header "Object Overhead"

keys = ["object instantiation memory usage"]
shas = helpers.getAvailableShas(keys)

header "Objects"
linechart helpers.summarizeShasForKey(shas, keys[0])
