helpers = require 'sha_summarizer'
keys = ["object instantiation: vanilla object creation", "object instantiation: clunk creation"]
shas = helpers.getAvailableShas(keys)

header "Instantiation Speed"
barchart helpers.reportKeysAcrossShas([keys[0]], shas)

header "Instantiation Speed with many keys"
barchart helpers.reportKeysAcrossShas([keys[1]], shas)

