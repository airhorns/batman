class Twitter.Tweet extends Batman.Model
  @hasMany 'comments'
  
  # @validatesLengthOf 'body', minimum: 3
  
  formatted: @property ->
    @text.replace(/@([\w]+)/g, '@<a href="#">$1</a>')
         .replace(/#([\w]+)/g, '<a href="#!/%23$1" class="hashtag">#$1</a>')
         .replace(/(http[^\s]+)/g, '<a href="$1">$1</a>')
  
  avatarLink: @property ->
    @profile_image_url.replace('_normal', '')
  
  timestamp: @property ->
    date = new Date @created_at
    date.toTimeString().split(' ')[0] + ' on ' + date.toDateString()
  
  hasComments: @property ->
    @get('comments').length
  
  showComments: =>
    Batman.redirect('/' + @id + '/comments')
  
  newComment: =>
    Batman.redirect('/' + @id + '/comment')