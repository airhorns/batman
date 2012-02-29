helpers = require 'sha_summarizer'
qs = (length) -> ('?' for i in [0...length]).join(', ')

header "Hash Speed - lower is better"

keys = ['hash performance: object-key setting', 'hash performance: object-key retrieval', 'hash performance: string-key setting', 'hash performance: string-key retrieval']
shas = helpers.getAvailableShas(keys)

barchart helpers.reportKeysAcrossShas(keys, shas)
