header "Hash Class Comparison"

qs = (length) ->
  x = ['?']
  result = []
  result = result.concat x for i in [0...length]
  result.join(', ')

keys = ['hash memory usage', 'simple hash memory usage', 'set memory usage', 'simple set memory usage']
shas = query "SELECT DISTINCT (CONCAT(sha, ' ', human)) AS 'readable_sha', sha FROM Reports WHERE Reports.key IN (#{qs(keys.length)})", keys...

param "sha_a", select(shas), label: "SHA A:", updateOnChange: true
param "sha_b", select(shas), label: "SHA B:", updateOnChange: true
param "sha_c", select(shas), label: "SHA C:", updateOnChange: true
param "sha_d", select(shas), label: "SHA D:", updateOnChange: true

shas = [params.sha_a, params.sha_b]
queryString = " SELECT Points.x, Points.y, Reports.key FROM Points
                LEFT JOIN Reports ON (Points.ReportId = Reports.id)
                WHERE
                  Reports.key IN (#{qs(keys.length)}) AND
                  Reports.sha IN (#{qs(shas.length)})"

points = new Summarizer(query(queryString, keys..., shas...))
points.categorize 'x'
aggregator = aggregator = points.aggregate 'memoryvalues'
aggregator.inital = {}
aggregator.inital[key] = 0 for key in keys
aggregator.map = (record) -> @[record.get('key')] = record.get('y')
aggregator.reduce = (callback) -> callback(@)

defs = {}
for key in keys
  do (key) ->
    defs[key] = (record) -> record.get('memoryvalues')[key]

points = points.addFields(defs).without('memoryvalues')

linechart points
