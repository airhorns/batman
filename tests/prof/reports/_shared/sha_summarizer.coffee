paramsAdded = false

exports =
  qs: (length) -> ('?' for i in [0...length]).join(', ')

  summarize: (keys) ->
    shas = exports.getAvailableShas(keys)
    exports.summarizeShasForKey(shas, keys[0])

  getAvailableShas: (keys) ->
    if !paramsAdded
      # Get a list of shas which have reports for any of the keys
      shas = query "SELECT DISTINCT (CONCAT(sha, ' ', human)) AS 'readable_sha', sha FROM Reports WHERE Reports.key IN (#{exports.qs(keys.length)})", keys...

      paramsAdded = true
      param "sha_a", select(shas), label: "SHA A:", updateOnChange: true
      param "sha_b", select(shas), label: "SHA B:", updateOnChange: true
      param "sha_c", select(shas), label: "SHA C:", updateOnChange: true
      param "sha_d", select(shas), label: "SHA D:", updateOnChange: true

    shas = [params.sha_a || '', params.sha_b || '', params.sha_c || '', params.sha_d || '']

  summarizeShasForKey: (shas, key) ->
    queryString = "SELECT Points.x, Points.y, Reports.sha FROM Points
                   LEFT JOIN Reports ON (Points.ReportId = Reports.id)
                   WHERE
                    Reports.key = ? AND
                    Reports.sha IN (#{exports.qs(shas.length)})"

    results = query queryString, key, shas...
    pivoted = results.pivot 'sha', 'y', {default: 0}

  summarizeKeysForSha: (keys, sha) ->
    queryString = "SELECT Points.x, Points.y, Reports.key FROM Points
                   LEFT JOIN Reports ON (Points.ReportId = Reports.id)
                   WHERE
                    Reports.sha = ? AND
                    Reports.key IN (#{exports.qs(keys.length)})"

    results = query queryString, sha, keys...
    pivoted = results.pivot 'key', 'y', {default: 0}

  reportKeysAcrossShas: (keys, shas, type = 'mean') ->
    queryString = " SELECT Reports.sha, Points.y, Reports.key FROM Points
                    LEFT JOIN Reports ON (Points.ReportId = Reports.id)
                    WHERE
                      Points.note = '#{type}' AND
                      Reports.key IN (#{exports.qs(keys.length)}) AND
                      Reports.sha IN (#{exports.qs(shas.length)})"

    results = query queryString, keys..., shas...
    pivoted = results.pivot 'key', 'y', {default: 0}

output exports
