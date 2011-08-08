class Twitter.Tweet extends Batman.Model
  #@hasMany 'comments'
  
  # @validatesLengthOf 'body', minimum: 3
  
  @accessor 'formatted', 
    get: ->
      @text.replace(/@([\w]+)/g, '@<a href="#">$1</a>')
           .replace(/#([\w]+)/g, '<a href="#!/%23$1" class="hashtag">#$1</a>')
           .replace(/(http[^\s]+)/g, '<a href="$1">$1</a>')
  
  @accessor 'avatarLink'
    get: -> @profile_image_url.replace('_normal', '')
  
  @accessor 'timestamp'
    get: ->
      date = new Date @created_at
      date.toTimeString().split(' ')[0] + ' on ' + date.toDateString()
  
  @accessor 'hasComments'
    get: -> @get('comments').length
  
  showComments: =>
    Batman.redirect('/' + @id + '/comments')
  
  newComment: =>
    Batman.redirect('/' + @id + '/comment')
