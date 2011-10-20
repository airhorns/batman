header "Hash Memory Usage"

shas = query "SELECT DISTINCT sha FROM Reports"

hashClass = Resultset.build 'name', 'value', ->
  @push ["Hash", "hash memory usage"]
  @push ["SimpleHash", "simple hash memory usage"]

param "key", select(hashClass), label: "Hash class:", updateOnChange: true
param "sha_a", select(shas), label: "SHA A:", updateOnChange: true
param "sha_b", select(shas), label: "SHA B:", updateOnChange: true

shas = [params.sha_a, params.sha_b]
points = new Summarizer(query "SELECT Points.x, Points.y, Reports.sha FROM Points LEFT JOIN Reports ON (Points.ReportId = Reports.id) WHERE Reports.key = ? AND Reports.sha IN (?, ?)", params.key, params.sha_a, params.sha_b)

points.categorize 'x'
aggregator = aggregator = points.aggregate 'memoryvalues'
aggregator.inital = {}
aggregator.inital[sha] = 0 for sha in shas
aggregator.map = (record) -> @[record.get('sha')] = record.get('y')
aggregator.reduce = (callback) -> callback(@)

defs = {}
for sha in shas
  do (sha) ->
    defs[sha] = (record) -> record.get('memoryvalues')[sha]

points = points.addFields(defs).without('memoryvalues')

linechart points

