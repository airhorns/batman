class Twitter.CommentsController extends Batman.Controller
  index: (params) ->
    @tweet = Twitter.Tweet.find(params.id)
  
  new: (params) ->
    @tweet = Twitter.Tweet.find(params.id)
    
    @comment = new Twitter.Comment
    @comment.set('tweet', @tweet)
    
    @comment.submit = =>
      @comment.save()
      Batman.redirect('/' + params.id + '/comments')
