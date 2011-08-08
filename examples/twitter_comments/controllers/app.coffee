class Twitter.AppController extends Batman.Controller
  index: ->
    
  query: (params) ->
    query = decodeURIComponent(params.query)
    
    Twitter.set('query', query)
    Twitter.Tweet.destroyAll()
    
    new Batman.JSONPRequest(url: 'http://search.twitter.com/search.json', data: {q: query}).success (json) =>
      for result in json.results
        new Tweet(result).save()
