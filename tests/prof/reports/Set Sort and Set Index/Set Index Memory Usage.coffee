header "Set Index Memory Usage"

qs = (length) ->
  x = ['?']
  result = []
  result = result.concat x for i in [0...length]
  result.join(', ')

keys = ['set index memory usage']
shas = query("SELECT DISTINCT (CONCAT(sha, ' ', human)) AS 'readable_sha', sha FROM Reports WHERE Reports.key IN (#{qs(keys.length)})", keys...)

param "sha_a", select(shas), label: "SHA A:", updateOnChange: true
param "sha_b", select(shas), label: "SHA B:", updateOnChange: true
param "sha_c", select(shas), label: "SHA C:", updateOnChange: true
param "sha_d", select(shas), label: "SHA D:", updateOnChange: true

shas = [params.sha_a, params.sha_b, params.sha_c, params.sha_d]
points = new Summarizer(query "SELECT Points.x, Points.y, Reports.sha FROM Points LEFT JOIN Reports ON (Points.ReportId = Reports.id) WHERE Reports.key = ? AND Reports.sha IN (?, ?, ?, ?)", keys[0], shas...)

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
