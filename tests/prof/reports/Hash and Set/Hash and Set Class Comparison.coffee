header "Hash Class Comparison"

shas = query "SELECT DISTINCT sha FROM Reports"

keys = ['hash memory usage', 'simple hash memory usage', 'set memory usage', 'simple set memory usage']
param "sha", select(shas), label: "SHA:", updateOnChange: true

shas = [params.sha_a, params.sha_b]
points = new Summarizer(query "SELECT Points.x, Points.y, Reports.key FROM Points LEFT JOIN Reports ON (Points.ReportId = Reports.id) WHERE Reports.key IN (?, ?) AND Reports.sha = ?", keys[0], keys[1], params.sha)

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
