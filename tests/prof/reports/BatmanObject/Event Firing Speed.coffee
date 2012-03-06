helpers = require 'sha_summarizer'

keys = ['event firing: once per object','event firing: many on same object','event firing: once per object with one handler','event firing: many on same object with one handler','event firing: once per object with ten handlers','event firing: many on same object with ten handlers']
shas = helpers.getAvailableShas(keys)

header "Firing with no handlers"
barchart helpers.reportKeysAcrossShas([keys[0], keys[3]], shas)

header "Firing with one handlers"
barchart helpers.reportKeysAcrossShas([keys[1], keys[4]], shas)

header "Firing with ten handlers"
barchart helpers.reportKeysAcrossShas([keys[2], keys[5]], shas)
