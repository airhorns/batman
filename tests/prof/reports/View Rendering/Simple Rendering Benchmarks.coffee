header "Simple Rendering"

qs = (length) ->
  x = ['?']
  result = []
  result = result.concat x for i in [0...length]
  result.join(', ')

keys = ['set sorting: simple set sorting']
shas = query("SELECT DISTINCT (CONCAT(sha, ' ', human)) AS 'readable_sha', sha FROM Reports WHERE Reports.key IN (#{qs(keys.length)})", keys...)

param "sha_a", select(shas), label: "SHA A:", updateOnChange: true
param "sha_b", select(shas), label: "SHA B:", updateOnChange: true
param "sha_c", select(shas), label: "SHA C:", updateOnChange: true
param "sha_d", select(shas), label: "SHA D:", updateOnChange: true

shas = [params.sha_a, params.sha_b, params.sha_c, params.sha_d]
queryString = " SELECT Reports.sha, Points.y, Reports.key FROM Points
                LEFT JOIN Reports ON (Points.ReportId = Reports.id)
                WHERE
                  Points.note = 'mean' AND
                  Reports.key IN (#{qs(keys.length)}) AND
                  Reports.sha IN (#{qs(shas.length)})"

points = new Summarizer(query(queryString, keys..., shas...))
points.categorize 'sha'
aggregator = aggregator = points.aggregate 'memoryvalues'
aggregator.inital = {}
aggregator.inital[key] = 0 for key in keys
aggregator.map = (record) -> @[record.get('key')] = record.get('y')
aggregator.reduce = (callback) -> callback(@)

defs = {}
for key in keys
  do (key) ->
    defs[key] = (record) -> record.get('memoryvalues')[key]

points = points.addFields(defs).without('memoryvalues', 'key')

debug points
await points, ->
  debug arguments
barchart points

