#
# batman.jquery.coffee
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
#

# Include this file instead of batman.nodep if your
# project already uses jQuery. It will map a few
# batman.js methods to existing jQuery methods.

Batman.Request::send = (data) ->
  options =
    type: @get 'method'
    dataType: @get 'type'
    data: data || @get 'data'
    username: @get 'username'
    password: @get 'password'
    beforeSend: =>
      @loading yes

    success: (response) =>
      @set 'response', response
      @success response

    error: (xhr, status, error) =>
      @set 'response', error
      @error error

    complete: =>
      @loading no
      @loaded yes

  if @get 'method' in ['PUT', 'POST']
    options.contentType = @get 'contentType'
  jQuery.ajax @get('url'), options

Batman.mixins.animation =
  show: (addToParent) ->
    jq = $(@)
    show = ->
      jq.show 600

    if addToParent
      addToParent.append?.appendChild @
      addToParent.before?.parentNode.insertBefore @, addToParent.before

      jq.hide()
      setTimeout show, 0
    else
      show()
    @
  hide: (removeFromParent) ->
    $(@).hide 600, =>
      @parentNode?.removeChild @
    @
