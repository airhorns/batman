helpers = require 'sha_summarizer'
qs = (length) -> ('?' for i in [0...length]).join(', ')


keys = ['set performance: object member adding']
shas = helpers.getAvailableShas(keys)

header "Setting Speed"
barchart helpers.reportKeysAcrossShas(['set performance: object member adding', 'set performance: string member adding'], shas)

header "Removal Speed"
barchart helpers.reportKeysAcrossShas(['set performance: object member removal', 'set performance: string member removal'], shas)

header "Membership Check Speed"
barchart helpers.reportKeysAcrossShas(['set performance: object membership check', 'set performance: string membership check'], shas)

header "Haystack Removal Speed"
barchart helpers.reportKeysAcrossShas(['set performance: haystack object member removal'], shas)
