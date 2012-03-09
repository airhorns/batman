helpers = require 'sha_summarizer'

keys = ['event firing: once per object with no handlers','event firing: many on same object with no handlers','event firing: once per object with one handler','event firing: many on same object with one handler','event firing: once per object with ten handlers','event firing: many on same object with ten handlers']
shas = helpers.getAvailableShas(keys)

header "Firing with no handler"
barchart helpers.reportKeysAcrossShas([keys[0], keys[1]], shas)

header "Firing with one handlers"
barchart helpers.reportKeysAcrossShas([keys[2], keys[3]], shas)

header "Firing with ten handlers"
barchart helpers.reportKeysAcrossShas([keys[4], keys[5]], shas)
