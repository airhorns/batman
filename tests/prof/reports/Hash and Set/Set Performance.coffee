helpers = require 'sha_summarizer'
qs = (length) -> ('?' for i in [0...length]).join(', ')

keys = ['set performance: object member adding']
shas = helpers.getAvailableShas(keys)

header "Iteration Speed"
barchart helpers.reportKeysAcrossShas(['set performance: object member iteration', 'set performance: string member iteration'], shas)

header "Membership Check Speed"
barchart helpers.reportKeysAcrossShas(['set performance: object membership check', 'set performance: string membership check'], shas)

header "Addition Speed"
barchart helpers.reportKeysAcrossShas(['set performance: object member adding', 'set performance: string member adding'], shas)

header "Removal Speed"
barchart helpers.reportKeysAcrossShas(['set performance: object member removal', 'set performance: string member removal'], shas)

header "Haystack Removal Speed"
barchart helpers.reportKeysAcrossShas(['set performance: haystack object member removal', 'set performance: haystack string member removal'], shas)
