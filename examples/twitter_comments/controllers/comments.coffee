class Twitter.CommentsController extends Batman.Controller
  index: (params) ->
    @tweet = Tweet.find(params.id)
  
  new: (params) ->
    @tweet = Tweet.find(params.id)
    
    @comment = new Comment
    @comment.set('tweet', @tweet)
    
    @comment.submit = =>
      @comment.save()
      Batman.redirect('/' + params.id + '/comments')
